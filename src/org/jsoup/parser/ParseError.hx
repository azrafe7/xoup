package org.jsoup.parser;

/**
 * A Parse Error records an error in the input HTML that occurs in either the tokenisation or the tree building phase.
 */
class ParseError {
    private var pos:Int;
    private errorMsg:String;

    public function new(pos:Int, errorMsg:String) {
        this.pos = pos;
        this.errorMsg = errorMsg;
    }

	//NOTE(az): removed
    /*ParseError(int pos, String errorFormat, Object... args) {
        this.errorMsg = String.format(errorFormat, args);
        this.pos = pos;
    }*/

    /**
     * Retrieve the error message.
     * @return the error message.
     */
    public function getErrorMessage():String {
        return errorMsg;
    }

    /**
     * Retrieves the offset of the error.
     * @return error offset within input
     */
    public function getPosition():Int {
        return pos;
    }

    //@Override
    public function toString():String {
        return pos + ": " + errorMsg;
    }
}
