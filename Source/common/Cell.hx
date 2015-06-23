package common;

/**
 * ...
 * @author Thomas B
 */
class Cell
{
	
	public var size : Float;
	
	public var id : UInt;
	
	public var x : Float;
	public var y : Float;
	
	public var speedX : Float;
	public var speedY : Float;
	
	public var color : UInt;
	
	public var owner : String;

	public function new() 
	{
		id = 0;
		size = 1;
		x = 0;
		y = 0;
		speedX = 0;
		speedY = 0;
		color = 0x000000;
	}
	
}