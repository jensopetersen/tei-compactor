xquery version "3.0";

declare namespace tei="httc://www.tei-c.org/ns/1.0";
declare namespace functx = "httc://www.functx.com";
declare namespace tc = "https://github.com/jensopetersen/tei-compactor";

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

declare function local:add-ns-node(
 $elem as element(),
 $prefix as xs:string,
 $ns-uri as xs:string
) as element() {
   element { node-name($elem) } {
       for $prefix in in-scope-prefixes($elem)
       return
           try {
               namespace { $prefix } { namespace-uri-for-prefix($prefix, $elem) }
           } catch * {
               ()
           },
       namespace { $prefix } { $ns-uri },
       for $attribute in $elem/@*
              return attribute {name($attribute)} {$attribute},
       $elem/node()
   }
};

declare function local:build-paths($doc as item()*, $attributes-to-suppress-from-paths as xs:string*, $attributes-to-output-with-value as xs:string*, $empty-elements-to-remove as xs:string*, $target as xs:string) as element()* {
    let $paths :=
        (:we gather nodes from the document; comments and pis are not yet supported:)
        let $nodes := 
            (:if we are building a tree, we only need element and text nodes; if we list paths, we need attribute nodes as well:)
            if ($target eq 'paths')
            then ($doc/descendant-or-self::element(), $doc/descendant-or-self::text(), $doc/descendant-or-self::node()/attribute::*)
            else ($doc/descendant-or-self::element(), $doc/descendant-or-self::text())
        let $nodes := 
            for $node in $nodes
            where not(name($node) = $empty-elements-to-remove)
            return $node
        return
            for $node in $nodes
            (:for each node, we construct its path to the document element:)
            let $ancestors := $node/ancestor::*
            let $ancestors :=
                string-join
                (
                for $ancestor at $i in $ancestors
                return
                    (:construct the path by concatenating …:)
                    concat
                    (
                    (:each ancestor name,:)
                    name($ancestor)
                    ,
                    string-join
                    (
                    (:the ancestor attributes, represented as predicates:)
                    local:handle-attributes($ancestor, $attributes-to-suppress-from-paths, $attributes-to-output-with-value, $target)
                    )
                    ,
                    (:and a slash, except on the node parent:)
                    if ($i eq count($ancestors))
                    then ''
                    else '/'
                    )
                )
            (:attach the type of the node to the ancestor path, adding …:)
            let $node-type :=
                (:'text()' for text nodes,:)
                if ($node instance of text())
                then 'text()'
                else
                    (:the name of the node plus any attributes for element nodes,:)
                    if ($node instance of element())
                    then concat(name($node), local:handle-attributes($node, $attributes-to-suppress-from-paths, $attributes-to-output-with-value, $target))
                    else
                        (:and the name of the attribute for attribute nodes, except for the attributes suppressed.:)
                        if ($node instance of attribute() and not(name($node) = $attributes-to-suppress-from-paths))
                        then concat('@', name($node))
                        else ''
            (:and return the concatenation of ancestor path and node type with a slash:)
            return 
                concat
                    (
                    $ancestors
                    , 
                    (:if there is no ancestor path, at the document element, do not attach a slash:)
                    if ($ancestors and $node-type) 
                    then '/' 
                    else ''
                    , 
                    $node-type
                    )
    let $paths-count := count($paths)
    let $distinct-paths := distinct-values($paths)
    let $paths :=
        <paths tc:count="{$paths-count}">
            {
            for $path at $sequence-number in $distinct-paths
            (:for $path at $n in ($paths):)
            let $count := count($paths[. eq $path])
            let $depth := count(tokenize(replace($path, '/text\(\)', ''), '/'))
            (:make text and attribute nodes appear immediately after their element node:) 
            order by replace(replace($path, '/text()', ' /text()'), '@', ' @')
            return
                <path tc:depth="{$depth}" tc:count="{$count}" tc:seq-no="{$sequence-number}">{$path}</path>
            }
        </paths>
return $paths

};

declare function local:handle-attributes($node as element(), $attributes-to-suppress-from-paths as item()*, $attributes-to-output-with-value as item()*, $target as xs:string) as xs:string? {
    let $attributes := $node/attribute()
        let $attributes :=
            for $attribute in $attributes
            where not(name($attribute) =  $attributes-to-suppress-from-paths)
            return 
                concat(
                    '[@', name($attribute)
                    , 
                    if (name($attribute) = $attributes-to-output-with-value) 
                    then concat('=', '"', $attribute/string(), '"', ']') 
                    else ']'
                    )
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
        let $depth := $child/@tc:depth
        let $count := $child/@tc:count
        let $seq-no := $child/@tc:seq-no
        (:the following regexes can probably be expressed moe elegantly:)
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
            let $attributes := tokenize($attributes, '\]\[')
            return
                element {$name}
                {attribute tc:depth {$depth}, attribute tc:count {$count}, attribute tc:seq-no {$seq-no}
                ,
                for $attribute in $attributes
                let $attribute := normalize-space(replace(replace(replace($attribute, '\[', ' '), '\]', ' '), '@', ' '))
                let $attribute-name := functx:substring-before-if-contains($attribute, '=')
                let $attribute-value := 
                    if (contains($attribute, '='))
                    then functx:substring-after-if-contains($attribute, '=')
                    else ''
                let $attribute-value := replace($attribute-value, '"', '')
                return
                    if ($attribute-name)
                    then
                        attribute {$attribute-name} {
                        if ($attribute-value) 
                        then $attribute-value
                        else
                            if ($attribute eq 'dim' and $name eq 'space')
                            then 'horizontal'
                            else
                                if ($attribute eq 'level' and $name eq 'title')
                                then 'a'
                                else
                                    if ($attribute eq 'type' and $name eq 'castItem')
                                    then 'role'
                                    else
                                        if ($attribute eq 'rows' and $name eq 'cell')
                                        then '1'
                                        else
                                        if ($attribute eq 'default' and $name eq 'sourceDesc')
                                        then 'true'
                                        else
                                        if ($attribute eq 'xml:id')
                                        then concat('uuid-', util:uuid())
                                        else 'x'
          }
          else ()
          ,
          $text}
      }
};

declare function local:construct-compacted-tree($doc as item()*, $attributes-to-suppress-from-paths as xs:string*, $attributes-to-output-with-value as xs:string*, $empty-elements-to-remove as xs:string*, $path-attributes-to-remove-from-trees as xs:string*, $default-namespaced-element as element(), $orders as element(), $target as xs:string) as element()* {
    let $paths := local:build-paths($doc, $attributes-to-suppress-from-paths, $attributes-to-output-with-value, $empty-elements-to-remove, $target)
    let $pruned-paths := local:prune-paths($paths)
    let $element-list := local:make-element-list($pruned-paths)
    let $compacted-tree := local:build-tree($element-list/*, $path-attributes-to-remove-from-trees)
    let $compacted-tree := local:order-children($compacted-tree, $orders)
    let $compacted-tree := 
            element {node-name($default-namespaced-element)}
        {$default-namespaced-element/@*, $compacted-tree/*}
    let $compacted-tree := local:add-ns-node($compacted-tree, "ext", "http://exist-db.org/mods/extension")
    let $compacted-tree := local:add-ns-node($compacted-tree, "xsi", "http://www.w3.org/2001/XMLSchema-instance")
    let $compacted-tree := local:add-ns-node($compacted-tree, "schemaLocation", "www.tei-c.org/release/xml/tei/custom/schema/xsd/tei_all.xsd")
    return $compacted-tree

};

declare function local:get-level($node as element()) as xs:integer {
    $node/@tc:depth
};

(: author: Jens Erat, https://stackoverflow.com/questions/21527660/transforming-sequence-of-elements-to-tree :)
(:slightly modified to exclude attributes:)
declare function local:build-tree($nodes as element()*, $path-attributes-to-remove-from-trees as xs:string*) as element()* {
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
            let $attributes := $node/@*
            return
                for $attribute in $attributes
                where not(name($attribute) = $path-attributes-to-remove-from-trees)
                return attribute {name($attribute)} {$attribute}
            ,
            (: Copy all other subnodes, including text, pi, elements, comments :)
            $node/node()
            ,
            (: If there are children, recursively build the subtree :)
            if ($children)
            then local:build-tree($children, $path-attributes-to-remove-from-trees)
            else ()
    }
};

declare function local:order-children($element as element(), $orders as element()+) as element() {
    element {node-name($element)}
        {$element/@*,
        let $element-name := local-name($element)
        let $order-local := $orders/order[parents/parent = $element-name]
        let $order-local := $order-local/children/item/text()
        let $children := $element/node()
        let $children-names := 
            for $child in $children
            return local-name($child)
        return
            if ($children-names = $order-local)
            then
                for $item in $order-local
                return
                    if ($item eq '*')
                    then 
                        for $child in $children[not(local-name(.) = $order-local)]
                        return 
                            if ($child instance of element())
                            then local:order-children($child, $orders)
                            else ()
                    else 
                        for $child in $children[local-name(.) eq $item]
                        return 
                            if ($child instance of element())
                            then local:order-children($child, $orders)
                            else ()
                else
                    for $child in $children
                    return 
                        if ($child instance of element())
                        then 
                            if ($orders) 
                            then local:order-children($child, $orders)
                            else ()
                        else $child
                    
      }
};


let $orders :=
<orders>
    <order>
        <parents>
            <parent>TEI</parent>
        </parents>
        <children>
            <item>teiHeader</item>
            <item>text</item>
        </children>
    </order>
    <order>
        <parents>
            <parent>teiHeader</parent>
        </parents>
        <children>
            <item>fileDesc</item>
            <item>profileDesc</item>
            <item>revisionDesc</item>
            <item>*</item>
        </children>
    </order>
    <order>
        <parents>
            <parent>fileDesc</parent>
        </parents>
        <children>
            <item>titleStmt</item>
            <item>editionStmt</item>
            <item>extent</item>
            <item>publicationStmt</item>
            <item>seriesStmt</item>
            <item>notesStmt</item>
            <item>sourceDesc</item>
            <item>*</item>
        </children>
    </order>
    <order>
        <parents>
            <parent>titleStmt</parent>
        </parents>
        <children>
            <item>title</item>
            <item>author</item>
            <item>editor</item>
            <item>sponsor</item>
            <item>funder</item>
            <item>principal</item>
            <item>respStmt</item>
            <item>*</item>
        </children>
    </order>
    <order>
        <parents>
            <parent>publicationStmt</parent>
        </parents>
        <children>
            <item>publisher</item>
            <item>distributor</item>
            <item>authority</item>
            <item>pubPlace</item>
            <item>address</item>
            <item>idno</item>
            <item>availability</item>
            <item>date</item>
            <item>licence</item>
            <item>*</item>
        </children>
    </order>
    <order>
        <parents>
            <parent>biblFull</parent>
        </parents>
        <children>
            <item>titleStmt</item>
            <item>editionStmt</item>
            <item>extent</item>
            <item>publicationStmt</item>
            <item>sourceDesc</item>
            <item>*</item>
        </children>
    </order>
    <order>
        <parents>
            <parent>msIdentifier</parent>
        </parents>
        <children>
            <item>country</item>
            <item>region</item>
            <item>settlement</item>
            <item>repository</item>
            <item>collection</item>
            <item>idno</item>
            <item>msName</item>
            <item>*</item>
        </children>
    </order>
    <order>
        <parents>
            <parent>text</parent>
        </parents>
        <children>
            <item>front</item>
            <item>body</item>
            <item>back</item>
        </children>
    </order>
    <order>
        <parents>
            <parent>div</parent>
            <parent>castGroup</parent>
        </parents>
        <children>
            <item>head</item>
            <item>list</item>
            <item>p</item>
            <item>*</item>
            <item>trailer</item>
        </children>
    </order>
    <order>
        <parents>
            <parent>app</parent>
        </parents>
        <children><item>lem</item><item>rdgGrp</item>item><item>rdg</item><item>*</item></children>
    </order>
    <order>
        <parents>
            <parent>sp</parent>
        </parents>
        <children><item>speaker</item><item>*</item></children>
    </order>
</orders>

let $doc := doc('/db/apps/shakespeare/data/ham.xml')
(:let $doc := doc('/db/test/abel_leibmedicus_1699.TEI-P5.xml'):)

let $default-namespaced-element := <TEI xmlns="http://www.tei-c.org/ns/1.0"/>
let $attributes-to-suppress-from-paths := ''
(:('xml:id', 'n'):)
let $attributes-to-output-with-value := 'who'
(:('type', 'rend', 'rendition'):)
let $empty-elements-to-remove := ('pb', 'lb', 'cb', 'milestone')
let $path-attributes-to-remove-from-trees := ('tc:count', 'tc:seq-no', 'tc:depth')

let $target := 'compacted-tree'

return 
    if ($target eq 'paths')
    then local:build-paths($doc, $attributes-to-suppress-from-paths, $attributes-to-output-with-value, $empty-elements-to-remove, $target)
    else local:construct-compacted-tree($doc/*, $attributes-to-suppress-from-paths, $attributes-to-output-with-value, $empty-elements-to-remove, $path-attributes-to-remove-from-trees, $default-namespaced-element, $orders, $target)