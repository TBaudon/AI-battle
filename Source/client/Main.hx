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
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.utils.ByteArray;
import openfl.utils.Endian;

class Main extends Sprite{
	
	var mServer : Socket;
	
	var mServerTime : Float;
	
	var mCurrentMessageLength : UInt;
	
	var mCells : Array<Cell>;
	var mCellViewMap : Map<Cell, CellView>;
	
	var mPlayers : Array<Player>;
	var mMe : Player;
	
	var mMessageBuffer : String;
	
	var mBytebuffer : ByteArray;
	var mTempByteBuff : ByteArray;
	
	var mPingTxt : TextField;
	
	public function new () {
		super ();
		
		mBytebuffer = new ByteArray();
		mTempByteBuff = new ByteArray();
		
		mServer = new Socket("radstar.fr", 2084);
		mServer.endian = Endian.LITTLE_ENDIAN;
		mServer.addEventListener(Event.CONNECT, onConnected);
		mServer.addEventListener(IOErrorEvent.IO_ERROR, onError);
		mServer.addEventListener(ProgressEvent.SOCKET_DATA, onData);
		
		mCurrentMessageLength = 0;
		mMessageBuffer = "";
		
		mCells = new Array<Cell>();
		mCellViewMap = new Map<Cell, CellView>();
		mPlayers = new Array<Player>();
		
		mPingTxt = new TextField();
		mPingTxt.selectable = false;
		mPingTxt.defaultTextFormat = new TextFormat("arial", 18, 0x339933);
		mPingTxt.autoSize = TextFieldAutoSize.LEFT;
		addChild(mPingTxt);
		
		mServer.connect("radstar.fr", 2084);
		
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	function onEnterFrame(e:Event):Void {
		
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
		while (mServer.bytesAvailable > 0 ) {
			mMessageBuffer += mServer.readUTFBytes(mServer.bytesAvailable);
			var messages = mMessageBuffer.split('\n');
			mMessageBuffer = messages[messages.length - 1];
			
			for (message in messages)
				if(message != null && message != "")
					readMessage(message);
		}
	}
	
	function readMessage(message : String) {
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
			case Messages.LOGGED :
				onLogged(message.content);
			case Messages.USERJOINED :
				onUserJoined(message.content);
			case Messages.PING :
				onPing(message.content);
			case Messages.USERLEFT :
				onUserLeave(message.content);
			case Messages.LATENCY :
				onLatency(message.content);
		}
	}
	
	function onLatency(latency : Float) {
		mPingTxt.text = "Ping : " + Math.ceil(latency);
	}
	
	function onUserLeave(name:String) {
		var player = getPlayer(name);
		if (player != null) {
			for (cell in player.getCells()){
				mCells.remove(cell);
				removeChild(mCellViewMap[cell]);
				mCellViewMap.remove(cell);
			}
			mPlayers.remove(player);
			player.destroy();
		}
	}
	
	function onPing(content : Dynamic) {
		sendMessage(Messages.PONG, "p");
	}
	
	function onLogged(content:Dynamic) {
		var usersHere : Array<{name : String, cells : Array<Dynamic>}> = content.others;
		for (user in usersHere) {
			var player = new Player(user.name);
			if (user.name == content.name)
				mMe = player;
			mPlayers.push(player);
			
			for (cell in user.cells) { 
				onCellMessage(cell);
			}
		}
		mServerTime = content.serverTime;
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
		if (content.name != mMe.getName())
			mPlayers.push(new Player(content.name));
	}
	
	function onCellMessage(c : Dynamic) {
		var cell : Cell = getCell(c.id);
		var toAdd = false;
		
		if (cell == null) {
			cell = new Cell();
			toAdd = true;
		}
		
		cell.id = c.id;
		cell.x = c.x;
		cell.y = c.y;
		cell.owner = c.owner;
		cell.speedX = c.speedX;
		cell.speedY = c.speedY;
		cell.size = c.size;
		cell.color = c.color;
		
		if (toAdd)
			addCell(cell, cell.owner);
	}
	
	function addCell(cell : Cell, owner : String) {
		mCells.push(cell);
		var player = getPlayer(owner);
		if (player != null)
			player.addCell(cell);
		var cellView = new CellView(cell);
		mCellViewMap[cell] = cellView;
		addChild(cellView);
	}
	
	function getCell(id : UInt) : Cell{
		for (cell in mCells)
			if (cell.id == id) return cell;
		return null;
	}
	
	function getPlayer(name : String) : Player {
		for (player in mPlayers)
			if (player.getName() == name)
				return player;
		return null;
	}
	
	
}