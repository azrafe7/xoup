package org.jsoup.safety;

import org.jsoup.helper.Validate;
import org.jsoup.nodes.*;
import org.jsoup.parser.Tag;
import org.jsoup.select.NodeTraversor;
import org.jsoup.select.NodeVisitor;
import org.jsoup.safety.Whitelist;

/**
 The whitelist based HTML cleaner. Use to ensure that end-user provided HTML contains only the elements and attributes
 that you are expecting; no junk, and no cross-site scripting attacks!
 <p>
 The HTML cleaner parses the input as HTML and then runs it through a white-list, so the output HTML can only contain
 HTML that is allowed by the whitelist.
 </p>
 <p>
 It is assumed that the input HTML is a body fragment; the clean methods only pull from the source's body, and the
 canned white-lists only allow body contained tags.
 </p>
 <p>
 Rather than interacting directly with a Cleaner object, generally see the {@code clean} methods in {@link org.jsoup.Jsoup}.
 </p>
 */
@:allow(org.jsoup.safety.CleaningVisitor)
class Cleaner {
    private var whitelist:Whitelist;

    /**
     Create a new cleaner, that sanitizes documents using the supplied whitelist.
     @param whitelist white-list to clean with
     */
    public function new(whitelist:Whitelist) {
        Validate.notNull(whitelist);
        this.whitelist = whitelist;
    }

    /**
     Creates a new, clean document, from the original dirty document, containing only elements allowed by the whitelist.
     The original document is not modified. Only elements from the dirt document's <code>body</code> are used.
     @param dirtyDocument Untrusted base document to clean.
     @return cleaned document.
     */
    public function clean(dirtyDocument:Document):Document {
        Validate.notNull(dirtyDocument);

        var clean:Document = Document.createShell(dirtyDocument.getBaseUri());
        if (dirtyDocument.body() != null) // frameset documents won't have a body. the clean doc will have empty body.
            copySafeNodes(dirtyDocument.body(), clean.body());

        return clean;
    }

    /**
     Determines if the input document is valid, against the whitelist. It is considered valid if all the tags and attributes
     in the input HTML are allowed by the whitelist.
     <p>
     This method can be used as a validator for user input forms. An invalid document will still be cleaned successfully
     using the {@link #clean(Document)} document. If using as a validator, it is recommended to still clean the document
     to ensure enforced attributes are set correctly, and that the output is tidied.
     </p>
     @param dirtyDocument document to test
     @return true if no tags or attributes need to be removed; false if they do
     */
    public function isValid(dirtyDocument:Document):Bool {
        Validate.notNull(dirtyDocument);

        var clean:Document = Document.createShell(dirtyDocument.getBaseUri());
        var numDiscarded:Int = copySafeNodes(dirtyDocument.body(), clean.body());
        return numDiscarded == 0;
    }


    private function copySafeNodes(source:Element, dest:Element):Int {
        var cleaningVisitor = new CleaningVisitor(source, dest, this);
        var traversor = new NodeTraversor(cleaningVisitor);
        traversor.traverse(source);
        return cleaningVisitor.numDiscarded;
    }

    private function createSafeElement(sourceEl:Element):ElementMeta {
        var sourceTag:String = sourceEl.getTagName();
        var destAttrs = new Attributes();
        var dest = new Element(Tag.valueOf(sourceTag), sourceEl.getBaseUri(), destAttrs);
        var numDiscarded:Int = 0;

        var sourceAttrs:Attributes = sourceEl.getAttributes();
        for (sourceAttr in sourceAttrs) {
            if (whitelist.isSafeAttribute(sourceTag, sourceEl, sourceAttr))
                destAttrs.putAttr(sourceAttr);
            else
                numDiscarded++;
        }
        var enforcedAttrs:Attributes = whitelist.getEnforcedAttributes(sourceTag);
        destAttrs.addAll(enforcedAttrs);

        return new ElementMeta(dest, numDiscarded);
    }

}


/**
 Iterates the input and copies trusted nodes (tags, attributes, text) into the destination.
 */
@:allow(org.jsoup.safety.Cleaner)
/*private final*/ class CleaningVisitor /*implements NodeVisitor*/ {
	private var numDiscarded:Int = 0;
	private var root:Element;
	private var destination:Element; // current element to append nodes to
	private var owner:Cleaner;

	private function new(root:Element, destination:Element, owner:Cleaner) {
		this.root = root;
		this.destination = destination;
		this.owner = owner;
	}

	public function head(source:Node, depth:Int):Void {
		if (Std.is(source, Element)) {
			var sourceEl:Element = cast source;

			if (owner.whitelist.isSafeTag(sourceEl.getTagName())) { // safe, clone and copy safe attrs
				var meta:ElementMeta = owner.createSafeElement(sourceEl);
				var destChild:Element = meta.el;
				destination.appendChild(destChild);

				numDiscarded += meta.numAttribsDiscarded;
				destination = destChild;
			} else if (source != root) { // not a safe tag, so don't add. don't count root against discarded.
				numDiscarded++;
			}
		} else if (Std.is(source, TextNode)) {
			var sourceText:TextNode = cast source;
			var destText = new TextNode(sourceText.getWholeText(), source.getBaseUri());
			destination.appendChild(destText);
		} else if (Std.is(source, DataNode) && owner.whitelist.isSafeTag(source.parent().nodeName())) {
		  var sourceData:DataNode = cast source;
		  var destData = new DataNode(sourceData.getWholeData(), source.getBaseUri());
		  destination.appendChild(destData);
		} else { // else, we don't care about comments, xml proc instructions, etc
			numDiscarded++;
		}
	}

	public function tail(source:Node, depth:Int):Void {
		if (Std.is(source, Element) && owner.whitelist.isSafeTag(source.nodeName())) {
			destination = destination.parent(); // would have descended, so pop destination stack
		}
	}
}

@:allow(org.jsoup.safety.Cleaner)
@:allow(org.jsoup.safety.CleaningVisitor)
/*private static*/ class ElementMeta {
	var el:Element;
	var numAttribsDiscarded:Int;

	function new(el:Element, numAttribsDiscarded:Int) {
		this.el = el;
		this.numAttribsDiscarded = numAttribsDiscarded;
	}
}

