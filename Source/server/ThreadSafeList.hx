package server;

#if neko
import neko.vm.Mutex;
#elseif cpp
import cpp.vm.Mutex;
#end

/**
 * ...
 * @author Thomas B
 */
class ThreadSafeList<T>
{

	var mList:Array<T>;
	var mMutex : Mutex;
	
	public var length(get, null) : UInt;
	
	public function new() {
		mList = new Array<T>();
		mMutex = new Mutex();
	}
	
	public function push(elem : T) {
		mMutex.acquire();
		mList.push(elem);
		mMutex.release();
	}
	
	public function get(i : UInt) : T {
		mMutex.acquire();
		var rep = mList[i];
		mMutex.release();
		return rep;
	}
	
	public function remove(item : T) {
		mMutex.acquire();
		mList.remove(item);
		mMutex.release();
	}
	
	public function pop() : T {
		mMutex.acquire();
		var rep = mList.pop();
		mMutex.release();
		return rep;
	}
	
	public function iterator() {
		return mList.iterator();
	}
	
	function get_length():UInt {
		mMutex.acquire();
		var rep = mList.length;
		mMutex.release();
		return rep;
	}
	
}