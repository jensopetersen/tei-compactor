xquery version "3.0";

declare namespace rng="http://relaxng.org/ns/structure/1.0";

declare function local:content-to-element($content-name as xs:string) as xs:string* {
    let $elements := collection('/db/test/rng')//rng:define[not(@combine)][./@name eq $content-name]//rng:ref
(:    let $log := util:log("DEBUG", ("##$element): ", $element)):)
    let $elements := 
        
        for $element in $elements
        let $name := $element/@name/string()
        return 
            if (contains($name, '.') and not($name eq 'macro.anyXML'))
            then local:content-to-element($name)
            else $name
    let $elements := distinct-values($elements)
(:    let $log := util:log("DEBUG", ("##$element): ", $element)):)
    return
        for $element in $elements
        return <child>{$element}</child>
};

let $definitions := collection('/db/test/rng')//rng:define[not(@combine)][not(contains(./@name, '.'))]
(:[./@name eq 'div']:)

return
    <definitions>{
    for $definition in $definitions
    let $parent := $definition/@name/string()
    let $children := $definition//rng:ref[contains(./@name, 'content')]/@name/string()
    let $children := 
        for $child in $children
        return local:content-to-element($child)
    order by $parent
        return
            <order>
            <parent>{$parent}</parent>
            <children>{$children}</children>
            </order>
    }</definitions>