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
	
	var mPingCounter : Float;
	var mPingPeriod : Float;
	var mLastTime : Float;
	
	var mRunSleepTime : Float;
	var mSyncPeriod : Float;
	var mSyncCounter : Float;
	
	var mPolicyServer : Thread;
	
	var mConfig : Dynamic;

	static function main() {
		new Main();
	}
	
	public function new() {
		
		mConfig = Json.parse(File.getContent("config.json"));
		
		mHost = new Host(Host.localhost());
		#if debug
		Lib.println("Debug serveur");
		#end
		Lib.println("Server launched on " + mHost);
		
		mUsers = new ThreadSafeList<User>();
		mUsersToRemove = new ThreadSafeList<User>();
		
		mPolicyServer = Thread.create(policyServer);
		
		mLastID = 0;
		mPingCounter = 0;
		mLastTime = Sys.time();
		mRunSleepTime = 1 / mConfig.runFrequency;
		mPingPeriod = 1 / mConfig.pingFrequency;
		mSyncCounter = 0;
		mSyncPeriod = 1 / mConfig.syncFrequency;
		
		mSocket = new Socket();
		mSocket.bind(mHost, Config.PORT);
		mSocket.listen(mConfig.maxPendingConnections);
		
		mAccetpThread = Thread.create(clientConnectionThread);
		run();
	}
	
	function policyServer() {
		var socket = new Socket();
		socket.bind(mHost, Config.PORT + 1);
		socket.listen(mConfig.maxPendingConnections);
		
		Sys.println("Policy server created.");
		
		while (true) {
			var c : Socket = socket.accept();
			var policy = File.getContent("crossdomain.xml") + "\r"+String.fromCharCode(0);
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
			
			mPingCounter += delta;
			var sendPing = false;
			if (mPingCounter >= mPingPeriod) {
				sendPing = true;
				mPingCounter = 0;
			}
			
			mSyncCounter += delta;
			for (user in mUsers) {
				if (sendPing) user.sendPing();
				user.update(delta);
				if (mSyncCounter >= mSyncPeriod) {
					mSyncCounter = 0;
					user.sync();
				}
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