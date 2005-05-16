include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = LuceneKit_Index

LuceneKit_Index_OBJC_FILES = \
	LCFieldInfo.m \
	LCFieldInfos.m \
	LCFieldsReader.m \
	LCFieldsWriter.m \
	LCTerm.m \
	LCTermBuffer.m \
	LCTermEnum.m \
	LCTermInfo.m \
	LCTermInfosReader.m \
	LCTermInfosWriter.m \
	LCTermVectorOffsetInfo.m \
	LCTermVectorsReader.m \
	LCTermVectorsWriter.m \
	LCSegmentInfo.m \
	LCSegmentInfos.m \
	LCSegmentTermDocs.m \
	LCSegmentTermEnum.m \
	LCSegmentTermVector.m \
	LCSegmentTermPositionVector.m \
	LCSegmentTermPositions.m \
	LCSegmentMergeInfo.m \
	LCSegmentMergeQueue.m \
	LCSegmentMerger.m \
	LCSegmentReader.m \
	LCMultiReader.m \
	LCIndexReader.m \
	LCIndexWriter.m \
	LCDocumentWriter.m \
	LCFilterIndexReader.m \
	LCCompoundFileReader.m \
	LCCompoundFileWriter.m \
	LCMultipleTermPositions.m

ifeq ($(test), yes)
LuceneKit_Index_OBJC_FILES += \
	TestMockIndexInput.m \
	TestMockIndexOutput.m \
	TestFieldsReader.m \
	TestCompoundFile.m \
	TestFilterIndexReader.m \
	TestIndexWriter.m \
	TestTermInfos.m \
	TestSegmentReader.m \
	TestTermVectorsReader.m \
	TestTermVectorsWriter.m \
	TestSegmentTermDocs.m \
	TestSegmentTermEnum.m \
	TestMultiReader.m \
	TestSegmentMerger.m \
	TestIndexReader.m \
	TestDocHelper.m
endif

LuceneKit_Index_INCLUDE_DIRS += -I../..

-include ../../GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include ../../GNUmakefile.postamble
