package client;

import common.Cell;
import common.Messages;
import haxe.Json;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.events.MouseEvent;
import openfl.Lib;
import openfl.net.Socket;
import openfl.utils.Endian;

class Main extends Sprite{
	
	var mServer : Socket;
	var mName : String;
	
	var mServerTime : Float;
	
	var mCurrentMessageLength : UInt;
	
	var mCells : Array<Cell>;
	
	public function new () {
		super ();
		
		mServer = new Socket("localhost", 2084);
		mServer.endian = Endian.LITTLE_ENDIAN;
		mServer.addEventListener(Event.CONNECT, onConnected);
		mServer.addEventListener(IOErrorEvent.IO_ERROR, onError);
		mServer.addEventListener(ProgressEvent.SOCKET_DATA, onData);
		
		mCurrentMessageLength = 0;
		
		mCells = new Array<Cell>();
		
		mServer.connect("localhost", 2084);
		
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	function onEnterFrame(e:Event):Void 
	{
		graphics.clear();
		for (cell in mCells) {
			graphics.beginFill(cell.color);
			graphics.drawCircle(cell.x, cell.y, cell.size);
		}
	}
	
	function sendMessage(name : String, data : Dynamic) {
		var message = {
			name : name,
			content : data
		};
		
		var string = Json.stringify(message);
		mServer.writeUTF(string);
		mServer.flush();
	}
	
	function onData(e:ProgressEvent):Void {
		while (mServer.bytesAvailable >= 4) {
			if(mCurrentMessageLength == 0)
				mCurrentMessageLength = mServer.readInt();
			if (mCurrentMessageLength > mServer.bytesAvailable)
				return;
			readMessage();
		}
	}
	
	function readMessage() {
		var message = mServer.readUTFBytes(mCurrentMessageLength);
		try{
			onMessage(Json.parse(message));
		}catch (e : Dynamic) {
			trace(e, message);	
		}
		mCurrentMessageLength = 0;
	}
	
	function onMessage(message:{name : String, content : Dynamic}) {
		switch(message.name) {
			case Messages.CELL :
				onCellMessage(message.content);
			case Messages.KILL : 
				onKillMessage(message.content);
			case Messages.LOGGED :
				onLogged(message.content);
			case Messages.USERJOINED :
				onUserJoined(message.content);
			case Messages.PING :
				onPing(message.content);
		}
	}
	
	function onPing(content : Dynamic) {
		mServerTime = content.emitTime;
		sendMessage(Messages.PONG, { emitTime : Date.now().getTime()});
	}
	
	function onLogged(content:Dynamic) {
		mName = content.name;
		var usersHere : Array<String> = content.others;
		for (user in usersHere)
			trace(user + " is here.");
		mServerTime = content.serverTime;
		trace("My name is " + mName + " and the time is " + Date.fromTime(mServerTime));
	}
	
	function onKillMessage(content:Dynamic) {
		trace("kill");
		var killedCell = getCell(content.id);
		trace(killedCell, content.id);
		mCells.remove(killedCell);
	}
	
	function onError(e:IOErrorEvent):Void {
		trace("error");
	}
	
	function onConnected(e:Event):Void {
		trace("connected");
	}
	
	function onUserJoined(content : Dynamic) : Void {
		trace(content.name + " joined.");
	}
	
	function onCellMessage(c : Dynamic) {
		var cell : Cell = getCell(c.id);
		if (cell == null){
			cell = new Cell();
			mCells.push(cell);
		}
		
		cell.id = c.id;
		cell.x = c.x;
		cell.y = c.y;
		cell.speedX = c.speedX;
		cell.speedY = c.speedY;
		cell.size = c.size;
		cell.color = c.color;
	}
	
	function getCell(id : UInt) : Cell{
		for (cell in mCells)
			if (cell.id == id) return cell;
		return null;
	}
	
	
}