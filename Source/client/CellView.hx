package client;
import common.Cell;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.Lib;

/**
 * ...
 * @author Thomas B
 */
class CellView extends Sprite
{
	
	var mCell : Cell;
	var mLastTime : UInt;

	public function new(cell : Cell){
		super();
		mCell = cell;
		
		graphics.beginFill(cell.color);
		graphics.drawCircle(0, 0, cell.size);
		
		mLastTime = Lib.getTimer();
		
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	function onEnterFrame(e:Event):Void {
		
		var time : UInt = Lib.getTimer();
		var delta = (time - mLastTime) / 1000;
		mLastTime = time;
		
		mCell.update(delta);
		
		x = mCell.x;
		y = mCell.y;
	}
	
}