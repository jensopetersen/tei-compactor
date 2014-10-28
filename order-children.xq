xquery version "3.0";

declare function local:sort-children($element as element(), $orders as element()+) as element() {
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
                            then local:sort-children($child, $orders)
                            else ()
                    else 
                        for $child in $children[local-name(.) eq $item]
                        return 
                            if ($child instance of element())
                            then local:sort-children($child, $orders)
                            else ()
                else
                    for $child in $children
                    return 
                        if ($child instance of element())
                        then 
                            if ($orders) 
                            then local:sort-children($child, $orders)
                            else ()
                        else $child
                    
      }
};


let $doc := doc('/db/test/test-doc.xml')/*
let $order-a := 
<order>
    <parents>
        <parent>TEI</parent>
        </parents>
    <children><item>front</item><item>body</item><item>back</item></children>
    </order>
let $order-c :=
    <order>
        <parents><parent>div</parent></parents>
            <children><item>head</item><item>*</item><item>trailer</item></children>
        </order>
let $orders :=
    <orders>
    {$order-a}
    {$order-c}
    </orders>
return local:sort-children($doc, $orders)