# Validation

`validate` returns what an invoice breaks, as a list of violations naming the
rule and the business term.

The catalogue is compiled from the Schematron the CEN publishes, so it is
complete by construction. `en16931ArtefactRelease` says which revision it was
read from, which is what lines a rejection up with a rule.
