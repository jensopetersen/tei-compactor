xquery version "3.0";

declare namespace rng="http://relaxng.org/ns/structure/1.0";

declare function local:content-to-element($content-name as xs:string) as xs:string* {
    let $elements := collection('/db/test/rng')//rng:define[not(@combine)][./@name eq $content-name]//rng:ref
    let $elements := 
        for $element in $elements
        let $name := $element/@name/string()
        return 
            if (contains($name, '.') and not($name eq 'macro.anyXML'))
            then local:content-to-element($name)
            else $name
    (:NB: using distinct-values() assumes that order of introduction is maintained, i.e. first appearance on an item is kept and the rest discarded, but the function is not deterministic, so another approach should be used:)
    let $elements := distinct-values($elements)
    return
        $elements
};

let $definitions := collection('/db/test/rng')//rng:define[not(@combine)][not(contains(./@name, '.'))]
(:[./@name eq 'text']:)

return
    <definitions>{
    for $definition in $definitions
    let $parent := $definition/@name/string()
    let $children := $definition//rng:ref[contains(./@name, 'content')]/@name/string()
    let $children := 
        for $child in $children
        return local:content-to-element($child)
    let $children :=
        for $child in $children
        return
            <child>{$child}</child>
    order by $parent
        return
            <order>
            <parent>{$parent}</parent>
            <children><child>text-node</child>{$children}</children>
            </order>
    }</definitions>