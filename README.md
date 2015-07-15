tei-compactor
==============

An XQuery script to list all unique paths in a TEI (Text Encoding Initiative) document and to construct on that basis a compact TEI instance incorporating only used paths.

Use cases:

- To check markup consistency
- To aid in schema construction
- To provide test document for rendering

As illustration, a compacted version of [a sample TEI document](https://raw.githubusercontent.com/TEIC/TEI-Simple/master/polygon/AbelLeibmedicus/abel_leibmedicus_1699.TEI-P5.xml) can be found [here](https://raw.githubusercontent.com/jensopetersen/tei-compactor/master/abel_leibmedicus_1699.TEI-P5.compacted.xml).

The script work on all XML, but was conceived for TEI.