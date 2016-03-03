package org.jsoup.helper;

import org.jsoup.Exceptions;

/**
 * Simple validation methods. Designed for jsoup internal use
 */
class Validate {
    
    function new() {}

    /**
     * Validates that the object is not null
     * @param obj object to test
     * @param msg message to output if validation fails
     */
    public static function notNull(obj, msg:String = "Object must not be null") {
        if (obj == null)
            throw new IllegalArgumentException(msg);
    }

    /**
     * Validates that the value is true
     * @param val object to test
     * @param msg message to output if validation fails
     */
    public static function isTrue(val:Bool, msg:String = "Must be true") {
        if (!val)
            throw new IllegalArgumentException(msg);
    }

    /**
     * Validates that the value is false
     * @param val object to test
     * @param msg message to output if validation fails
     */
    public static function isFalse(val:Bool, msg:String = "Must be false") {
        if (val)
            throw new IllegalArgumentException(msg);
    }

    /**
     * Validates that the array contains no null elements
     * @param objects the array to test
     * @param msg message to output if validation fails
     */
    public static function noNullElements<T>(objects:Iterable<T>, msg:String = "Array must not contain any null objects") {
        for (obj in objects)
            if (obj == null)
                throw new IllegalArgumentException(msg);
    }

    /**
     * Validates that the string is not empty
     * @param string the string to test
     * @param msg message to output if validation fails
     */
    public static function notEmpty(string:String, msg:String = "String must not be empty") {
        if (string == null || string.length == 0)
            throw new IllegalArgumentException(msg);
    }

    /**
     Cause a failure.
     @param msg message to output.
     */
    public static function fail(msg:String) {
        throw new IllegalArgumentException(msg);
    }
}
