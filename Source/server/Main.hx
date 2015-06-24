package server;

import common.Cell;
import common.Messages;
import haxe.Json;
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

	static function main() {
		new Main();
	}
	
	public function new() {
		mHost = new Host("localhost");
		Lib.println("Server launched on " + mHost);
		
		mUsers = new ThreadSafeList<User>();
		mUsersToRemove = new ThreadSafeList<User>();
		
		mLastID = 0;
		mPingCounter = 0;
		
		mSocket = new Socket();
		mSocket.bind(mHost, 2084);
		mSocket.listen(16);
		
		mAccetpThread = Thread.create(clientConnectionThread);
		run();
	}
	
	public function clientConnectionThread() {
		while (true) {
			Lib.println("Waiting for peer...");
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
			
			Sys.sleep(0.25);
			
			mPingCounter++;
			var sendPing = false;
			if (mPingCounter >= 25) {
				sendPing = true;
				mPingCounter = 0;
			}
			
			for (user in mUsers) {
				if (sendPing) user.sendPing();
				user.update();
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