package server;
import common.Cell;
import common.Messages;
import haxe.io.BufferInput;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.Json;
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
class User
{
	
	var mSocket : Socket;
	var mCells : Array<Cell>;
	var mName : String;
	var mConnected : Bool;
	var mServer : Main;
	var mListenThread : Thread;
	
	var mCurrentMessageLength : UInt;
	var mCurrentMessage : String;
	
	static var adjectives : Array<String> = ["Mighty" , "Powerful", "Awesome", "Yellow", "Blue", "Lazy", "Angry", "Shiny", "Super", "Weak", "Smart", "Sly", "Crying", "Radial"];
	static var name : Array<String> = ["Chicken", "Pig", "Dog", "Cat", "Banana", "Racoon", "Baby", "Shoe", "Human", "Jelly", "Guitar", "Screen", "Blob", "Fart", "Nerf", "Gun", "Mouse", "Horse"];
	static var cplmt : Array<String> = ["on steroïd" , "with ADHD", "with no legs", "in a box", "under water", "doing back flips", "on a plane", "in Uranus", "eating burger", "living the dream", "on coke", "is totaly stoned"];

	public function new(socket : Socket, main : Main) {
		mServer = main;
		mSocket = socket;
		mConnected = true;
		mCurrentMessage = "";
		mCurrentMessageLength = 0;
		mCells = new Array<Cell>();
		mName = adjectives[Std.random(adjectives.length)] + " " + name[Std.random(name.length)] + " " + cplmt[Std.random(cplmt.length)];
	}
	
	public function sendMessage(name : String, data : Dynamic) {
		var message = {
			name : name,
			content : data
		};
		
		var string = Json.stringify(message);
		try {
			mSocket.output.prepare(1 + string.length);
			mSocket.output.writeInt32(string.length);
			mSocket.output.writeString(string);
			mSocket.output.flush();
		}catch (e : Dynamic) {
			mConnected = false;
		}
	}
	
	public function startListenThread() {
		mListenThread = Thread.create(listenThread);
	}
	
	public function addCell() {
		var cell = new Cell();
		mCells.push(cell);
		cell.id = mServer.getCellId();
		cell.x = Std.random(300);
		cell.y = Std.random(300);
		cell.color = Std.random(0xcccccc+1);
		cell.size = 50;
		cell.owner = mName;
		mServer.sendToAll(Messages.CELL, cell);
	}
	
	public function login() {
		var connectedUser : Array<String> = new Array<String>();
		for (user in mServer.getUsers())
			connectedUser.push(user.getName());
		var time = Date.now().getTime();
		var message = { name : mName, others : connectedUser, serverTime : time };
		sendMessage(Messages.LOGGED, message);
		mServer.sendToAll(Messages.USERJOINED, { name : mName } );
	}
	
	public function isConnected() : Bool {
		return mConnected;
	}
	
	public function getName() : String {
		return mName;
	}
	
	function listenThread() {
		while(true){
			try {
				handleMessage();
			}catch (e : Dynamic) {
				mServer.planRemove(this);
				break;
			}
		}
	}
	
	function handleMessage() {
		var len = mSocket.input.readInt16();
		var message = mSocket.input.readString(len);
	}
	
}