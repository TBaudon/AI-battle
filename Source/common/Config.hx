package common;

/**
 * ...
 * @author Thomas B
 */
class Config
{

	public static inline var PORT : Int = 11000;
	
	#if release
	public static inline var HOST : String = "radstar.fr";
	#else
	public static inline var HOST : String = "localhost";
	#end
	
}