xquery version "3.0";

declare namespace rng="http://relaxng.org/ns/structure/1.0";

declare function local:delete-doubles($sequence as element(), $come-last as xs:string) as element()* {
    for $item in $sequence/*
    return
        if ($item eq $come-last)
        then
            if ($item/following-sibling::item = $item)
            then ()
            else $item
        else
            if (not($item/preceding-sibling::item = $item))
            then $item
            else ()
};

declare function local:content-to-element($content-name as xs:string) as xs:string* {
    let $elements := collection('/db/test/rng')//rng:define[not(@combine)][./@name eq $content-name]//rng:ref
        for $element in $elements
        let $name := $element/@name/string()
        return 
            if (not((contains($name, '.') and not($name eq 'macro.anyXML'))))
            then $name
            else local:content-to-element($name)
};

let $definitions := collection('/db/test/rng')//rng:define[not(@combine)][not(contains(./@name, '.'))]
(:[./@name eq 'div']:)

return
    <definitions>{
    for $definition in $definitions
    let $parent-name := $definition/@name/string()
    let $children-names := $definition//rng:ref[contains(./@name, 'content')]/@name/string()
    let $children-names := 
        for $child-name in $children-names
        return local:content-to-element($child-name)
    let $children-names := 
        <sequence>{
        for $item in $children-names
        return <item>{$item}</item>
    }</sequence>
    let $children-names := local:delete-doubles($children-names, $parent-name)
    let $children :=
        for $child-name in $children-names
        return
            <child>{$child-name/text()}</child>
    order by $parent-name
    return
        <order>
        <parent>{$parent-name}</parent>
        <children><child>text-node</child>{$children}</children>
        </order>
    }</definitions>