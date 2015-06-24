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
	
	public function update(delta : Float) {
		if (x < 0){
			x = 0;
			speedX *= -1;
		}
		if (x > 800) {
			x = 800;
			speedX *= -1;
		}
		
		if (y < 0){
			y = 0;
			speedY *= -1;
		}
		if (y > 600) {
			y = 600;
			speedY *= -1;
		}
		
		x += speedX * delta;
		y += speedY * delta;
	}
	
}