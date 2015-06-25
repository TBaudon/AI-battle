package server;

import common.Cell;
import common.Config;
import common.Messages;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;
import sys.net.Host;
import sys.net.Socket;

#if neko
import neko.Lib;
import neko.vm.Thread;
#elseif cpp
import cpp.Lib;
import cpp.vm.Thread;
#end

/**
 * ...
 * @author Thomas B
 */
class Main
{
	
	var mHost : Host;
	var mSocket : Socket;

	var mUsers : ThreadSafeList<User>;
	var mUsersToRemove : ThreadSafeList<User>;
	
	var mAccetpThread : Thread;
	
	var mLastID : UInt;
	
	var mPingCounter : UInt;
	var mLastTime : Float;
	
	var mRunSleepTime : Float;
	
	var mPolicyServer : Thread;

	static function main() {
		new Main();
	}
	
	public function new() {
		mHost = new Host(Host.localhost());
		Lib.println("Server launched on " + mHost);
		
		mUsers = new ThreadSafeList<User>();
		mUsersToRemove = new ThreadSafeList<User>();
		
		mPolicyServer = Thread.create(policyServer);
		
		mLastID = 0;
		mPingCounter = 0;
		mLastTime = Sys.time();
		mRunSleepTime = 0.25;
		
		mSocket = new Socket();
		mSocket.bind(new Host(Config.HOST), Config.PORT);
		mSocket.listen(16);
		
		mAccetpThread = Thread.create(clientConnectionThread);
		run();
	}
	
	function policyServer() {
		var socket = new Socket();
		socket.bind(new Host(Config.HOST), Config.PORT + 1);
		socket.listen(16);
		
		Sys.println("Policy server created.");
		
		while (true) {
			var c : Socket = socket.accept();
			var policy = File.getContent("policy.xml") + "\r"+String.fromCharCode(0);
			Lib.println(policy);
			c.write(policy);
		}
	}
	
	public function clientConnectionThread() {
		while (true) {
			var c = mSocket.accept();
			var user = new User(c, this);
			mUsers.push(user);
			Lib.println(user.getName() + " is connected.");
			user.login();
			user.startListenThread();
		}
	}
	
	public function run() {
		while (true) {
			
			Sys.sleep(mRunSleepTime);
			
			var time : Float = Sys.time();
			var delta : Float = time - mLastTime;
			mLastTime = time;
			
			mPingCounter++;
			var sendPing = false;
			if (mPingCounter >= 25) {
				sendPing = true;
				mPingCounter = 0;
			}
			
			for (user in mUsers) {
				if (sendPing) user.sendPing();
				user.update(delta);
			}
			
			while (mUsersToRemove.length > 0) {
				var removedUser : User = mUsersToRemove.pop();
				mUsers.remove(removedUser);
				sendToAll(Messages.USERLEFT, removedUser.getName());
				Lib.println(removedUser.getName() + " left.");
			}
		}
	}
	
	public function planRemove(user : User) {
		if(mUsersToRemove.indexOf(user) == -1)
			mUsersToRemove.push(user);
	}
	
	public function getUsers() : ThreadSafeList<User> {
		return mUsers;
	}
	
	public function sendToAll(messageName : String, data : Dynamic) {
		for(user in mUsers)
			user.sendMessage(messageName, data);
	}
	
	public function getCellId() : UInt {
		var id = mLastID;
		mLastID ++;
		return id;
	}
	
}