package org.jsoup.select;

import org.jsoup.nodes.Node;

/**
 * Depth-first node traversor. Use to iterate through all nodes under and including the specified root node.
 * <p>
 * This implementation does not use recursion, so a deep DOM does not risk blowing the stack.
 * </p>
 */
class NodeTraversor {
    private var visitor:NodeVisitor;

    /**
     * Create a new traversor.
     * @param visitor a class implementing the {@link NodeVisitor} interface, to be called when visiting each node.
     */
    public function new(visitor:NodeVisitor) {
        this.visitor = visitor;
    }

    /**
     * Start a depth-first traverse of the root and all of its descendants.
     * @param root the root node point to traverse.
     */
    public function traverse(root:Node):Void {
        var node:Node = root;
        var depth:Int = 0;
        
        while (node != null) {
            visitor.head(node, depth);
            if (node.childNodeSize() > 0) {
                node = node.childNode(0);
                depth++;
            } else {
                while (node.nextSibling() == null && depth > 0) {
                    visitor.tail(node, depth);
                    node = node.getParentNode();
                    depth--;
                }
                visitor.tail(node, depth);
                if (node == root)
                    break;
                node = node.nextSibling();
            }
        }
    }
}
