include(ECMOptionalAddSubdirectory)
ecm_optional_add_subdirectory(doc-valid2.1)
kdoctools_create_handbook(index.docbook INSTALL_DESTINATION ${HTML_INSTALL_DIR}/en_US)
