xquery version "3.0";

declare namespace rng="http://relaxng.org/ns/structure/1.0";

declare function local:content-to-element($content-name as xs:string) as element() {
    let $element := collection('/db/test/rng')//rng:define[not(@combine)][./@name eq $content-name]//rng:ref
(:    let $log := util:log("DEBUG", ("##$element): ", $element)):)
    return
        <elements>{
        for $element in $element
        let $name := $element/@name/string()
        return 
            if (contains($name, '.') and not($name eq 'macro.anyXML'))
            then local:content-to-element($name)
            else $name
        }</elements>
(:    element {node-name($element)}:)
(:    {$element/@*,:)
(:          for $child in $element/node():)
(:              return:)
(:               if ($child instance of element()):)
(:                 then local:content-to-element($child):)
(:                 else $child:)
(:      }:)
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