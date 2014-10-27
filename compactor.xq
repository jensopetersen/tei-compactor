xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";

declare function functx:substring-after-last-match
  ( $arg as xs:string? ,
    $regex as xs:string )  as xs:string {

   replace($arg,concat('^.*',$regex),'')
 } ;

declare function functx:substring-after-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-after($arg,$delim)
   else $arg
 } ;

declare function functx:substring-before-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-before($arg,$delim)
   else $arg
 } ;

declare function local:build-paths($doc as item()*, $attributes-to-suppress-from-paths as xs:string*, $attributes-to-output-with-value as xs:string*, $target as xs:string) as element()* {
    let $paths :=
        (:we gather nodes from the document; comments and pis are not yet supported:)
        let $nodes := 
            (:if we are building a tree, we only need element and text nodes; if we list paths, we need attribute nodes as well:)
            if ($target eq 'paths')
            then ($doc/descendant-or-self::element(), $doc/descendant-or-self::text(), $doc/descendant-or-self::attribute())
            else ($doc/descendant-or-self::element(), $doc/descendant-or-self::text())
        (:we order the nodes in document order (and remove duplicates, though here there should be none here):)
        let $nodes := $nodes/.
        return
            for $node in $nodes
            (:for each node, we construct its path to the document element:)
            let $ancestors := $node/ancestor::*
            let $ancestors :=
                string-join
                (
                for $ancestor at $i in $ancestors
                return
                    (:construct the unique path by concatenating …:)
                    concat
                    (
                    (:each ancestor qname,:)
                    name($ancestor)
                    ,
                    (:any attributes attached to ancestor element nodes, expressed as as a predicate:)
                    (:any attributes attached to sibling elements that are not attached to the ancestor in question, expressed as a negative predicate:)
                    string-join
                    (
                    (:get the ancestor attributes:)
                    local:handle-attributes($ancestor, $attributes-to-suppress-from-paths, $attributes-to-output-with-value, $target)
                    )
                    ,
                    (:string-joining with a slash:)
                    if ($i eq count($ancestors))
                    then ''
                    else '/'
                    )
                )
            (:attach the node type to the ancestor path:)
            let $node-type :=
                if ($node instance of text())
                then 'text()'
                else
                    if ($node instance of element())
                    then concat(name($node), local:handle-attributes($node, $attributes-to-suppress-from-paths, $attributes-to-output-with-value, $target))
                    else
                        if ($node instance of attribute() and not(name($node) = $attributes-to-suppress-from-paths))
                        then concat('@', name($node))
                        else ''
            (:and return the concatenation of ancestor path and node type with a slash:)
            return 
                (:if there is no ancestor path, do not attach a node type:)
                concat
                    (
                    $ancestors
                    , 
                    if ($ancestors and $node-type) 
                    then '/' 
                    else ''
                    , 
                    $node-type
                    )
                
    let $paths-count := count($paths)
    (:distinct-values() appears to maintain document order, but can this be replied upon?:)
    let $distinct-paths := distinct-values($paths)
    let $paths :=
        <paths count="{$paths-count}">
            {
            for $path at $sequence-number in $distinct-paths
            (:for $path at $n in ($paths):)
            let $count := count($paths[. eq $path])
            let $depth := count(tokenize(replace($path, '/text\(\)', ''), '/'))
            order by 
                replace(replace($path, '/text()', ' /text()'), '@', ' @')(:make text and attribute else nodes follow immediately after their element node:) 
                
            return
                <path depth="{$depth}" count="{$count}" sequence-number="{$sequence-number}">{$path}</path>
            }
        </paths>
return $paths

};
(:I am not quite sure that all this "missing attribute" thing is needed (or any good):)
declare function local:handle-attributes($node as element(), $attributes-to-suppress-from-paths as item()*, $attributes-to-output-with-value as item()*, $target as xs:string) as xs:string? {
    let $attributes := $node/attribute()
        let $attributes :=
            for $attribute in $attributes
            where not(name($attribute) =  $attributes-to-suppress-from-paths)
            return 
                concat('[@', name($attribute), if (name($attribute) = $attributes-to-output-with-value) then concat('=', '"', $attribute/string(), '"', ']') else ']')
        return
            string-join($attributes)
};

declare function local:prune-paths($paths as element()) as element() {
    element {node-name($paths)}
        {$paths/@*
        ,
        for $child in $paths/element()
        return
            if (($child/preceding-sibling::path/text(), $child/following-sibling::path/text()) = concat($child/text(), '/text()'))
            then ''
            else
                if (starts-with(functx:substring-after-last-match($child, '/'), '@'))
                then ''
                else
                    if (contains($child, '/'))
                    then
                        element {node-name($child)}
                        {$child/@*, functx:substring-after-last-match(replace($child, '/text\(\)', '[text()]'), '/')}
                    else
                        if (string-length($child))
                        then $child
                        else ''
      }
};

declare function local:make-element-list($element as element()) as element() {
    element {node-name($element)}
        {$element/@*
        ,
        for $child in $element/node()
        let $depth := $child/@depth
        let $count := $child/@count
        (:the following regexes can probably be expressed in a smarter way:)
        let $clean := replace($child, '\[not\(@.*?\)\]', '')
        let $name := functx:substring-before-if-contains($clean, '[')
        let $text :=
            if (matches(replace(functx:substring-after-if-contains($clean, '[t'), '\]', ''), 'ext\(\)')) 
            then 'text' 
            else ''
        let $attributes := 
            if (contains($clean, '['))
            then substring-after($clean, '[')
            else ''
      let $attributes := replace($attributes, 'text\(\)\]', '')
      let $attributes := tokenize(normalize-space(replace(replace(replace($attributes, '\[', ' '), '\]', ' '), '@', ' ')), ' ')
      return
          element {$name}
          {attribute depth {$depth}, attribute count {$count}
          , 
          for $attribute in $attributes
          return attribute {$attribute} {'x'},
          $text}
      }
};

declare function local:construct-compacted-tree($doc as item()*, $attributes-to-suppress-from-paths as xs:string*, $attributes-to-output-with-value as xs:string*, $target as xs:string) as element()* {
    let $paths := local:build-paths($doc, $attributes-to-suppress-from-paths, $attributes-to-output-with-value, $target)
    let $pruned-paths := local:prune-paths($paths)
    let $element-list := local:make-element-list($pruned-paths)
    let $compacted-tree := local:build-tree($element-list/*)
        return $compacted-tree
};

declare function local:get-level($node as element()) as xs:integer {
    $node/@depth
};

(: author: Jens Erat, https://stackoverflow.com/questions/21527660/transforming-sequence-of-elements-to-tree :)
declare function local:build-tree($nodes as element()*) as element()* {
    let $level := local:get-level($nodes[1])
    (: Process all nodes of current level :)
    for $node in $nodes
    where $level eq local:get-level($node)
    return
    (: Find next node of current level, if available :)
        let $next := ($node/following-sibling::*[local:get-level(.) le $level])[1]
        (: All nodes between the current node and the next node on same level are children :)
        let $children := $node/following-sibling::*[$node << . and (not($next) or . << $next)]
        return
            element { name($node) } {
            (: Copy node attributes :)
            $node/@*
            ,
            (: Copy all other subnodes, including text, pi, elements, comments :)
            $node/node()
            ,
            (: If there are children, recursively build the subtree :)
            if ($children)
            then local:build-tree($children)
            else ()
    }
};

let $doc := 
    <doc xml:id="x">
        <a>
            <b x="1" n="7">text1<e>text2</e>text3</b>
            <b>text0</b>
        </a>
        <a u="5">
            <c>
                <d y="2" z="3">text4-1</d>
                <d y="3" z="4">text4-2</d>
                <d y="4">text4-3</d>
                <d z="4">text4-4</d>
            </c>
        </a>
        <a>
            <c>
                <d y="4">text5-1<p n="6"/>text6-1</d>
            </c>
            <c>
                <d y="5">text5-2<p n="7"/>text6-2</d>
            </c>
        </a>
    </doc>
(:let $doc := doc('/db/test/test-doc.xml'):)
(:let $doc := doc('/db/apps/shakespeare/data/ham.xml'):)
let $doc := doc('/db/test/abel_leibmedicus_1699.TEI-P5.xml')

let $attributes-to-suppress-from-paths := ''
(:('xml:id', 'n'):)
let $attributes-to-output-with-value := ''
(:('type', 'rend', 'rendition'):)
let $empty-elements-to-remove := ''
(:('pb', 'lb', 'cb', 'milestone'):)
let $intermediate-attributes-to-remove-from-trees := ''
(:('path', 'count', 'sequence-number', 'level'):)
let $target := 'compacted-tree'

return 
    if ($target eq 'paths')
    then local:build-paths($doc, $attributes-to-suppress-from-paths, $attributes-to-output-with-value, $target)
    else local:construct-compacted-tree($doc, $attributes-to-suppress-from-paths, $attributes-to-output-with-value, $target)