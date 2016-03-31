Porting notes:

NOTES:

 - explicit get/set accessors (with fluent interface) to work around overloaded methods
   - also means many constructors/methods are conflated into one
 - using polygonal.ds (ListSet, ArrayList, Cloneable, etc.)
   - check if semantics are the same wrt java
 - removed hashcode (relying on string comparison for equaling contents (after some basic checks))
 - removed/skipped functionality related to network connection
 - using OrderedMap (f.e. see Dataset)
 - using hxUri (modified port of js-uri)
 - added "NOTE(" comments to recheck possible issues at a further stage
 
TODO:

 - convert node cloning to iterative version (to avoid stack overflows)
 - recheck !important notes