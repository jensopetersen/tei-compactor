xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";

declare function functx:substring-after-last-match
  ( $arg as xs:string? ,
    $regex as xs:string )  as xs:string {

   replace($arg,concat('^.*',$regex),'')
 } ;
 
declare function local:build-paths($doc as item()*, $attributes-to-suppress as xs:string*, $attributes-with-value-output as xs:string*) as element()* {
    let $paths :=
        (:we gather all element, attribute and text nodes in the document:)
        let $nodes := ($doc/descendant-or-self::element(), $doc/descendant-or-self::text(), $doc/descendant-or-self::attribute())
        return
            for $node in $nodes
            (:for each node, we construct its path to the document root element:)
            let $ancestors := $node/ancestor::*
            let $ancestors :=
                string-join
                (
                for $ancestor at $i in $ancestors
                return
                    (:construct the unique path by concatenating …:)
                    concat
                    (
                    (:the the ancestor qname,:)
                    name($ancestor)
                    ,
                    (:any attribute attached to element nodes, expressed as as a predicate:)
                    (:any attribute attached to sibling elements that is not attached to the ancestor in question, expressed as a negative predicate:)
                    string-join
                    (
                    (:get the ancestor attributes:)
                    local:handle-attributes($ancestor, $attributes-to-suppress, $attributes-with-value-output)
                    
                    ,
                    (:in the case of mixed contents, any text node or element node children, expressed as a predicate:)
                    if ($ancestor/node() instance of text() and $ancestor/node() instance of element())
                    then concat('[text()][', name($ancestor), ']')
                    else 
                        (:then check for text nodes separately, as predicate:)
                        if ($ancestor/node() instance of text())
                        then '[text()]'
                        else 
                            (:and for element nodes separately, as predicate:)
                            if ($ancestor/node() instance of element())
                            then concat('[', name($ancestor), ']')
                            else 'XXX'
                    )
                ,
                (:string-joining with a slash:)
                if ($i eq count($ancestors))
                then ''
                else '/'
                    )
                )
            (:attach the node type to the unique ancestor path:)
            let $node-type :=
                if ($node instance of text())
                then 'text()'
                else
                    if ($node instance of element())
                    then concat(name($node), local:handle-attributes($node, $attributes-to-suppress, $attributes-with-value-output))
                    else
                        if ($node instance of attribute() and not(name($node) =  $attributes-to-suppress))
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
                
    (:let $paths-count := count($paths[string-length(.) gt 0]) + 1:)
    let $paths-count := count($paths)
    let $distinct-paths := distinct-values($paths)
    let $paths :=
        <paths count="{$paths-count}">
            {
            for $path at $n in $distinct-paths
            (:for $path at $n in ($paths):)
            let $count := count($paths[. eq $path])
            let $depth := count(tokenize($path, '/'))
            order by $path, $depth
            (:order by string-length($path):)
            return
                <path depth="{$depth}" count="{$count}" n="{$n}">{$path}</path>
            }
        </paths>
return $paths

};


declare function local:handle-attributes($node as element(), $attributes-to-suppress as item()*, $attributes-with-value-output as item()*) as xs:string? {
    let $attributes := $node/attribute()
    (:get the attributes of ancestor sibling with the same name:)
    let $siblings := ($node/preceding-sibling::*, $node/following-sibling::*)
    let $same-name-siblings :=
        for $sibling in $siblings
        where name($sibling) eq name($node)
        return $sibling
    let $same-name-sibling-attributes := 
        for $same-name-sibling in $same-name-siblings
        return $same-name-sibling/attribute()
        (:filter away the attributes of same-name siblings that are the same as the ancestor attribute:)
    let $attribute-names := 
        for $attribute in $attributes
        return name($attribute)
    (:let $log := util:log("DEBUG", ("##$attributes): ", string-join($attributes))):)
    let $missing-same-name-sibling-attributes := 
        for $same-name-sibling-attribute in $same-name-sibling-attributes
        return
            if (name($same-name-sibling-attribute) = $attribute-names)
            then ()
            else $same-name-sibling-attribute
            (:let $log := util:log("DEBUG", ("##$missing-same-name-sibling-attributes): ", string-join($missing-same-name-sibling-attributes))):)
    (:format attributes as predicates:)
    let $attributes :=
        for $attribute in $attributes
        where not(name($attribute) =  $attributes-to-suppress)
        return 
            concat('[@', name($attribute), if (name($attribute) = $attributes-with-value-output) then concat('=', '"', $attribute/string(), '"', ']') else ']')
    (:format missing attributes as negative predicates:)
    let $missing-same-name-sibling-attributes :=
        for $missing-sibling-attribute in $missing-same-name-sibling-attributes
        return 
            concat('[not(@', name($missing-sibling-attribute), ')]')
    let $missing-same-name-sibling-attributes := distinct-values($missing-same-name-sibling-attributes)
    return
        concat(string-join($attributes), string-join($missing-same-name-sibling-attributes))
};

declare function local:prune-paths($paths as element()) as element() {
  element {node-name($paths)}
      {$paths/@*, 
      for $child in $paths/element()
              return
               if (($child/preceding-sibling::path/text(), $child/following-sibling::path/text()) = concat($child/text(), '/text()'))
               then ''
               else
                   if (starts-with(functx:substring-after-last-match($child, '/'), '@'))
                   then ''
                   else $child
               
      }
};

declare function local:reconstruct($doc as item()*, $attributes-to-suppress as xs:string*, $attributes-with-value-output as xs:string*) as element()* {
      let $paths := local:build-paths($doc, $attributes-to-suppress, $attributes-with-value-output)
      let $pruned-paths := local:prune-paths($paths)
      return $pruned-paths
               
      
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
      $node/@*,
      (: Copy all other subnodes, including text, pi, elements, comments :)
      $node/node(),

      (: If there are children, recursively build the subtree :)
      if ($children)
      then local:build-tree($children)
      else ()
    }
};

declare function local:paths-to-list($paths as element()) as element() {''};

let $doc := 
<doc xml:id="x">
    <a>
        <b x="1" n="7">text1<e>text2</e>text3</b>
        <b>text0</b>
        </a>
    <a u="5">
        <c>
            <d y="2" z="3">text4</d>
            </c>
    </a>
    <a>
        <c>
            <d y="4">text5<p n="6"/>text6</d>
            </c>
    </a>
</doc>

let $doc := doc('/db/test/test-doc.xml')
(:let $doc := doc('/db/apps/shakespeare/data/ham.xml')//tei:TEI/tei:text/tei:front:)
(: let $doc := doc('/db/test/abel_leibmedicus_1699.TEI-P5.xml')//tei:TEI:)

let $attributes-to-suppress := ''
(:('xml:id', 'n'):)
let $attributes-with-value-output := ('type')
let $target := 'paths'

return if ($target eq 'paths')
then local:build-paths($doc, $attributes-to-suppress, $attributes-with-value-output)
else local:reconstruct($doc, $attributes-to-suppress, $attributes-with-value-output)