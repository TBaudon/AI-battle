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
	var mServer : Main;
	var mListenThread : Thread;
	var mLatency : UInt;
	
	var mCurrentMessageLength : UInt;
	var mCurrentMessage : String;
	
	var mLastPingTime:Float;
	
	static var adjectives : Array<String> = ["Mighty" , "Powerful", "Awesome", "Yellow", "Blue", "Lazy", "Angry", "Shiny", "Super", "Weak", "Smart", "Sly", "Crying", "Radial"];
	static var name : Array<String> = ["Chicken", "Pig", "Dog", "Cat", "Banana", "Racoon", "Baby", "Shoe", "Human", "Jelly", "Guitar", "Screen", "Blob", "Fart", "Nerf", "Gun", "Mouse", "Horse"];
	static var cplmt : Array<String> = ["on steroïd" , "with ADHD", "with no legs", "in a box", "under water", "doing back flips", "on a plane", "in Uranus", "eating burger", "living the dream", "on coke", "is totaly stoned"];

	public function new(socket : Socket, main : Main) {
		mServer = main;
		mSocket = socket;
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
			//mSocket.output.writeUInt16(string.length);
			mSocket.output.writeString(string+'\n');
			mSocket.output.flush();
		}catch (e : Dynamic) {
			mServer.planRemove(this);
		}
	}
	
	public function sendPing() {
		mLastPingTime = Sys.time() * 1000;
		sendMessage(Messages.PING, "p" );
	}
	
	public function startListenThread() {
		mListenThread = Thread.create(listenThread);
	}
	
	public function update(delta : Float) {
		for (cell in mCells){
			cell.update(delta);
			mServer.sendToAll(Messages.CELL, cell);
		}
	}
	
	public function addCell() {
		var cell = new Cell();
		mCells.push(cell);
		cell.id = mServer.getCellId();
		cell.x = Std.random(800);
		cell.y = Std.random(600);
		cell.speedX = Std.random(200)-100;
		cell.speedY = Std.random(200)-100;
		cell.color = Std.random(0xcccccc+1);
		cell.size = 50;
		cell.owner = mName;
		mServer.sendToAll(Messages.CELL, cell);
	}
	
	public function login() {
		var connectedUser : Array<{name : String, cells : Array<Cell>}> = new Array<{name : String, cells : Array<Cell>}>();
		for (user in mServer.getUsers())
			connectedUser.push({name : user.getName(), cells : user.getCells()});
		var time = Date.now().getTime();
		var message = { name : mName, others : connectedUser, serverTime : time };
		sendMessage(Messages.LOGGED, message);
		mServer.sendToAll(Messages.USERJOINED, { name : mName } );
		addCell();
	}
	
	public function getName() : String {
		return mName;
	}
	
	public function getLatnecy() : UInt {
		return mLatency;
	}
	
	public function getCells() : Array<Cell> {
		return mCells;
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
		var len = mSocket.input.readUInt16();
		var message = Json.parse(mSocket.input.readString(len));
		
		switch(message.name) {
			case Messages.PONG :
				onPong();
		}
	}
	
	function onPong() {
		var time = Sys.time() * 1000;
		mLatency = cast ((time - mLastPingTime) / 2);
		sendMessage(Messages.LATENCY, mLatency);
	}
	
}