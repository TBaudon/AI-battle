package common;

/**
 * ...
 * @author Thomas B
 */
class Config
{

	public static inline var PORT : Int = 11000;
	
	#if debug
	public static inline var HOST : String = "10.33.1.57";
	#else
	public static inline var HOST : String = "radstar.fr";
	#end
	
}