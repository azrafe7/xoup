Porting notes:

NOTES:

 - explicit get/set accessors (with fluent interface) to work around overloaded methods
   - also means many constructors/methods are conflated into one
   - see if the Attributes param in Element's constructor could be made optional (special care is needed for that)
 - using polygonal.ds (ListSet, ArrayList, Cloneable, etc.)
   - check if/where semantics depart from java ones (f.e. I'm currently using a hack in wrap() which could be related to unmodifiableList, but I'm not sure)
 - removed hashcode (I'm currently relying on string comparison for equalling contents (after some basic checks))
 - removed/skipped functionality related to network connection
 - using OrderedMap (f.e. see Dataset)
 - using hxUri (modified port of js-uri)
 - added "NOTE(" comments to recheck possible issues at a further stage
 - added some "dummy" classes (can probably be removed - must search for it in notes)
 
 
TODO:

 - convert node cloning to an iterative version (to avoid stack overflows - for now it's recursive -)
 - make _some of_ the initializations lazy (mostly the ones using haxe.resources to make them work with js - used for htmlentities -)
 - check what can be inlined
 - recheck other !important notes
 - 