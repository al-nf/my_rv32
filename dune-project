(lang dune 3.22)

(name my_rv32)

(generate_opam_files true)

(source
 (github al-nf/my_rv32))

(authors "Alan Fung <alankjfung@gmail.com>")

(maintainers "Maintainer Name <maintainer@example.com>")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name my_rv32)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml)
 (tags
  ("add topics" "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
