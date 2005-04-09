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
	TestDocHelper.m \
	TestMockIndexInput.m \
	TestMockIndexOutput.m \
	TestTermInfos.m \
	TestSegmentReader.m \
	TestSegmentMerger.m \
	TestTermVectorsReader.m \
	TestTermVectorsWriter.m \
	TestIndexWriter.m
endif

LuceneKit_Index_INCLUDE_DIRS += -I../../Headers -I../

-include ../../GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include ../../GNUmakefile.postamble
