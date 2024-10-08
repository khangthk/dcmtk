/*
 *
 *  Copyright (C) 2000-2024, OFFIS e.V.
 *  All rights reserved.  See COPYRIGHT file for details.
 *
 *  This software and supporting documentation were developed by
 *
 *    OFFIS e.V.
 *    R&D Division Health
 *    Escherweg 2
 *    D-26121 Oldenburg, Germany
 *
 *
 *  Module: dcmsr
 *
 *  Author: Joerg Riesmeier
 *
 *  Purpose:
 *    classes: DSRCompositeTreeNode
 *
 */


#include "dcmtk/config/osconfig.h"    /* make sure OS specific configuration is included first */

#include "dcmtk/dcmsr/dsrtypes.h"
#include "dcmtk/dcmsr/dsrcomtn.h"
#include "dcmtk/dcmsr/dsrxmld.h"

#include "dcmtk/dcmdata/dcdeftag.h"
#include "dcmtk/dcmdata/dcuid.h"


DSRCompositeTreeNode::DSRCompositeTreeNode(const E_RelationshipType relationshipType)
  : DSRDocumentTreeNode(relationshipType, VT_Composite),
    DSRCompositeReferenceValue()
{
}


DSRCompositeTreeNode::DSRCompositeTreeNode(const DSRCompositeTreeNode &node)
  : DSRDocumentTreeNode(node),
    DSRCompositeReferenceValue(node)
{
}


DSRCompositeTreeNode::~DSRCompositeTreeNode()
{
}


DSRCompositeTreeNode *DSRCompositeTreeNode::clone() const
{
    return new DSRCompositeTreeNode(*this);
}


void DSRCompositeTreeNode::clear()
{
    DSRDocumentTreeNode::clear();
    DSRCompositeReferenceValue::clear();
}


OFBool DSRCompositeTreeNode::isEqual(const DSRDocumentTreeNode &node) const
{
    /* call comparison operator of base class (includes check of value type) */
    OFBool result = DSRDocumentTreeNode::isEqual(node);
    if (result)
    {
        /* it's safe to cast the type since the value type has already been checked */
        result = DSRCompositeReferenceValue::isEqual(OFstatic_cast(const DSRCompositeTreeNode &, node).getValue());
    }
    return result;
}


OFBool DSRCompositeTreeNode::isNotEqual(const DSRDocumentTreeNode &node) const
{
    /* call comparison operator of base class (includes check of value type) */
    OFBool result = DSRDocumentTreeNode::isNotEqual(node);
    if (!result)
    {
        /* it's safe to cast the type since the value type has already been checked */
        result = DSRCompositeReferenceValue::isNotEqual(OFstatic_cast(const DSRCompositeTreeNode &, node).getValue());
    }
    return result;
}


OFBool DSRCompositeTreeNode::isValid() const
{
    return DSRDocumentTreeNode::isValid() && hasValidValue();
}


OFBool DSRCompositeTreeNode::hasValidValue() const
{
    return DSRCompositeReferenceValue::isValid();
}


OFCondition DSRCompositeTreeNode::print(STD_NAMESPACE ostream &stream,
                                        const size_t flags) const
{
    OFCondition result = DSRDocumentTreeNode::print(stream, flags);
    if (result.good())
    {
        DCMSR_PRINT_ANSI_ESCAPE_CODE(DCMSR_ANSI_ESCAPE_CODE_DELIMITER)
        stream << "=";
        DCMSR_PRINT_ANSI_ESCAPE_CODE(DCMSR_ANSI_ESCAPE_CODE_ITEM_VALUE)
        result = DSRCompositeReferenceValue::print(stream, flags);
    }
    return result;
}


OFCondition DSRCompositeTreeNode::writeXML(STD_NAMESPACE ostream &stream,
                                           const size_t flags) const
{
    OFCondition result = EC_Normal;
    writeXMLItemStart(stream, flags);
    result = DSRDocumentTreeNode::writeXML(stream, flags);
    stream << "<value>" << OFendl;
    DSRCompositeReferenceValue::writeXML(stream, flags);
    stream << "</value>" << OFendl;
    writeXMLItemEnd(stream, flags);
    return result;
}


OFCondition DSRCompositeTreeNode::readContentItem(DcmItem &dataset,
                                                  const size_t flags)
{
    /* read ReferencedSOPSequence */
    return DSRCompositeReferenceValue::readSequence(dataset, DCM_ReferencedSOPSequence, "1" /* type */, flags);
}


OFCondition DSRCompositeTreeNode::writeContentItem(DcmItem &dataset) const
{
    /* write ReferencedSOPSequence */
    return DSRCompositeReferenceValue::writeSequence(dataset, DCM_ReferencedSOPSequence);
}


OFCondition DSRCompositeTreeNode::readXMLContentItem(const DSRXMLDocument &doc,
                                                     DSRXMLCursor cursor,
                                                     const size_t flags)
{
    /* retrieve value from XML element "value" */
    return DSRCompositeReferenceValue::readXML(doc, doc.getNamedChildNode(cursor, "value"), flags);
}


OFCondition DSRCompositeTreeNode::renderHTMLContentItem(STD_NAMESPACE ostream &docStream,
                                                        STD_NAMESPACE ostream &annexStream,
                                                        const size_t /* nestingLevel */,
                                                        size_t &annexNumber,
                                                        const size_t flags,
                                                        const char *urlPrefix) const
{
    /* render ConceptName */
    OFCondition result = renderHTMLConceptName(docStream, flags);
    /* render Reference */
    if (result.good())
    {
        result = DSRCompositeReferenceValue::renderHTML(docStream, annexStream, annexNumber, flags, urlPrefix);
        docStream << OFendl;
    }
    return result;
}


// comparison operators

OFBool operator==(const DSRCompositeTreeNode &lhs,
                  const DSRCompositeTreeNode &rhs)
{
    return lhs.isEqual(rhs);
}


OFBool operator!=(const DSRCompositeTreeNode &lhs,
                  const DSRCompositeTreeNode &rhs)
{
    return lhs.isNotEqual(rhs);
}
