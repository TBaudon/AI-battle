package client;
import common.Cell;

/**
 * ...
 * @author TBaudon
 */
class Player {

	var mName : String;
	var mCells : Array<Cell>;

	public function new(name : String) {
		mName = name;
		mCells = new Array<Cell>();
	}
	
	public function getName() : String {
		return mName;
	}
	
	public function addCell(cell : Cell) {
		mCells.push(cell);
	}
	
	public function getCells() : Array<Cell>{
		return mCells;
	}
	
	public function destroy() {
		while (mCells.length > 0)
			mCells.pop();
	}
	
}