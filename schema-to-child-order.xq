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
    let $parent-name := $definition/@name/string()
    let $children-names := $definition//rng:ref[contains(./@name, 'content')]/@name/string()
    let $children-names := 
        for $child-name in $children-names
        return local:content-to-element($child-name)
    let $children :=
        for $child-name in $children-names[not(. eq $parent-name)] (:self-nesting elements must be ordered last:)
        return
            <child>{$child-name}</child>
    let $children := 
        (
            $children
            ,
            if ($parent-name = $children-names)
            then <child>{$parent-name}</child>
            else ()
        )
    order by $parent-name
        return
            <order>
            <parent>{$parent-name}</parent>
            <children><child>text-node</child>{$children}</children>
            </order>
    }</definitions>