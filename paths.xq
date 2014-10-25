xquery version "3.0";

let $doc := 
<doc xml:id="x">
    <a>
        <b x="1">text1<e>text2</e>text3</b>
        </a>
    <a u="5">
        <c>
            <d y="2" z="3">text4</d>
            </c>
    </a>
    <a>
        <c>
            <e y="4">text5<p n="6"/>text6</e>
            </c>
    </a>
</doc>

let $doc := doc('/db/test/test-doc.xml')

(:let $doc := doc('/db/apps/shakespeare/data/ham.xml'):)
return 
    let $paths :=
(:        we gather all nodes in the document:)
        let $nodes := ($doc//element(), $doc//attribute(), $doc//text())
        let $log := util:log("DEBUG", ("##$nodes): ", string-join($nodes, ' || ')))
        for $node in $nodes
(:        for each node, we construct its path to the document root element; this path follows the element hierarchy:)
        let $ancestors := $node/ancestor::*
        let $log := util:log("DEBUG", ("##$ancestors1): ", concat($node/string(), ':', $node/string-join(ancestor::*/name(.), '/'))))
        
        let $ancestors := 
                string-join
                (
                for $ancestor at $i in $ancestors
                return 
                    concat
                    (
(:                        the ancestor qname:)
                        name($ancestor)
                        ,
(:                        any attribute attached to the node if it is an element, expressed as as a predicate:)
                        string-join
                        (
                            let $attributes := $ancestor/attribute()
                            for $attribute in $attributes
                            return concat('[@', name($attribute), ']'
                        )
                        ,
(:                        in the case of mixed contents, any text node or element node children, expressed as a predicate:)
                        if ($ancestor/text() and $ancestor/element())
                        then concat('[text()][', name($ancestor), ']')
                        else 
(:                            then check for text nodes separately, as predicate:)
                            if ($ancestor/text())
                            then '[text()]'
                            else 
(:                                and for element nodes separately, as predicate:)
                                if ($ancestor/element())
                                then concat('[', name($ancestor), ']')
                                else 'XXX'
                )
                    , if ($i eq count($ancestors)) then '' else '/'
                    )
                )
        let $node-type :=      
              if (normalize-space(string-join($node/text())) ne '' and $node/element())
              then '(text(), element())'
              else 
                  if (normalize-space(string-join($node/text())) ne '')
                  then 'text()'
                  else
                      if ($node/element())
                      then 'element()'
                      else 
                          (:if ($node/attribute())
                          then 'attribute()'
                          else:) '' (:attribute value:)
            
        return if ($ancestors)
        then concat($ancestors, if ($node-type) then '/' else '', $node-type)
        else ''
    let $paths := distinct-values($paths)
    return
        <paths>
            {
            for $path in $paths
            where string-length($path)
            order by $path
            return
                <path>{$path}</path>
            }
        </paths>
