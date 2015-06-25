package common;

/**
 * ...
 * @author Thomas B
 */
class Time
{
	
	static var mLastTime : Float;
	static var mDeltaArray : Array<Float>;

	public function new() 
	{
		
	}
	
	public static functon init() {
		
	}
	
	public static function smoothedDelta() : Float {
		#if flash
		var time : Float = flash.Lib.getTimer() / 1000;
		#else
		var time : Float = Sys.time();
		#end
		
		var delta = time - mLastTime();
	}
	
}