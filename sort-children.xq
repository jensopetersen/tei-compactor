xquery version "3.0";

declare function local:sort-children($element as element(), $order as element()+) as element() {
    element {node-name($element)}
        {$element/@*,
        let $element-name := local-name($element)
        let $order-local := $order/*[local-name(.) = $element-name]
        let $order-local := $order-local//text()
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
                            then local:sort-children($child, $order)
                            else ()
                    else 
                        for $child in $children[local-name(.) eq $item]
                        return 
                            if ($child instance of element())
                            then local:sort-children($child, $order)
                            else ()
                else
                    for $child in $children
                    return 
                        if ($child instance of element())
                        then 
                            if ($order) 
                            then local:sort-children($child, $order)
                            else ()
                            
                        else $child
                    
      }
};


let $doc := doc('/db/test/test-doc.xml')/*
let $order-a := <a><item>a</item><item>b</item><item>c</item></a>
let $order-c :=<c><item>d</item><item>e</item><item>*</item><item>f</item><item>g</item></c>
let $order :=
    <order>
    {$order-a}
    {$order-c}
    </order>
(:let $log := util:log("DEBUG", ("##$order-x): ", $order)):)
return local:sort-children($doc, $order)