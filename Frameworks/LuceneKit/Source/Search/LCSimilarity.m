#include "Search/LCSimilarity.h"

static float *NORM_TABLE;

@implementation LCSimilarity

+ (void) setDefaultSimilarity: (LCSimilarity *) d
{
}

+ (LCSimilarity *) defaultSimilarity
{
  return nil;
}

/** Cache of decoded bytes. */
- (id) init
{
  self = [super init];
  if (NORM_TABLE == NULL)
    {
      NORM_TABLE = malloc(sizeof(float)*256);
      int i;
      for(i = 0; i < 256; i++)
        NORM_TABLE[i++] = [LCSimilarity byteToFloat: (char)i];
    }
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

 /** Decodes a normalization factor stored in an index.
  *  @see #encodeNorm(float)
  */
+ (float) decodeNorm: (char) b
{
  return NORM_TABLE[b & 0xff]; // & 0xFF maps negative bytes to positive above 127
}

 /** Returns a table for decoding normalization bytes.
  * @see #encodeNorm(float)
  */
+ (float *) normDecoder
{
  return NORM_TABLE;
}

  /** Computes the normalization value for a field given the total number of
   * terms contained in a field.  These values, together with field boosts, are
   * stored in an index and multipled into scores for hits on each field by the
   * search code.
   *
   * <p>Matches in longer fields are less precise, so implementations of this
   * method usually return smaller values when <code>numTokens</code> is large,
   * and larger values when <code>numTokens</code> is small.
   *
   * <p>That these values are computed under {@link
   * IndexWriter#addDocument(org.apache.lucene.document.Document)} and stored then using
   * {@link #encodeNorm(float)}.  Thus they have limited precision, and documents
   * must be re-indexed if this method is altered.
   *
   * @param fieldName the name of the field
   * @param numTokens the total number of tokens contained in fields named
   * <i>fieldName</i> of <i>doc</i>.
   * @return a normalization factor for hits on this field of this document
   *
   * @see Field#setBoost(float)
   */
- (float) lengthNorm: (NSString *) fieldName numberOfTokens: (int) numTokens
{
}

  /** Computes the normalization value for a query given the sum of the squared
   * weights of each of the query terms.  This value is then multipled into the
   * weight of each query term.
   *
   * <p>This does not affect ranking, but rather just attempts to make scores
   * from different queries comparable.
   *
   * @param sumOfSquaredWeights the sum of the squares of query term weights
   * @return a normalization factor for query weights
   */
- (float) queryNorm: (float) sumOfSquredWeights
{
}

  /** Encodes a normalization factor for storage in an index.
   *
   * <p>The encoding uses a five-bit exponent and three-bit mantissa, thus
   * representing values from around 7x10^9 to 2x10^-9 with about one
   * significant decimal digit of accuracy.  Zero is also represented.
   * Negative numbers are rounded up to zero.  Values too large to represent
   * are rounded down to the largest representable value.  Positive values too
   * small to represent are rounded up to the smallest positive representable
   * value.
   *
   * @see Field#setBoost(float)
   */
+ (char) encodeNorm: (float) f
{
  return [LCSimilarity floatToByte: f];
}

+ (float) byteToFloat: (char) b
{
  if (b == 0) return 0.0f; // zero is a special case
  int mantissa = b & 7;
  int exponent = (b >> 3) & 31;
  int bits = ((exponent+(63-15)) << 24) | (mantissa << 21);

  // Float.intBitsToFloat(bits);
#if 0 // FIXME: not sure which one works
  int s = ((bits >> 31) == 0) ? 1 : -1;
  int e = ((bits >> 23) & 0xff);
  int m = (e == 0) ? (bits & 0x7fffff) << 1 : (bits & 0x7fffff) | 0x800000;
  float f = s * m * exp2f(e-150);
  return f;
#else
  // Assume C follows IEEE standard.
  union
    {
      float fl;
      char ch[4];
    } udata;
  udata.ch[3] = (bits >> 24) & 0xff;
  udata.ch[2] = (bits >> 16) & 0xff;
  udata.ch[1] = (bits >> 8) & 0xff;
  udata.ch[0] = bits & 0xff;
  return udata.fl;
#endif
}

+ (char) floatToByte: (float) f
{
  if (f < 0.0f)                                 // round negatives up to zero
    f = 0.0f;

  if (f == 0.0f)                                // zero is a special case
    return 0;

  //int bits = Float.floatToIntBits(f);           // parse float into parts
  // FIXME: not sure it works
  // Assume C follows IEEE standard.
  union
    {
      float fl;
      char ch[4];
    } udata;
  udata.fl = f;
  int bits = (((int)udata.ch[3] << 24) |
	      ((int)udata.ch[2] << 16) |
	      ((int)udata.ch[1] << 8) |
	      (int)udata.ch[0]);

  int mantissa = (bits & 0xffffff) >> 21;
  int exponent = (((bits >> 24) & 0x7f) - 63) + 15;

  if (exponent > 31) {                          // overflow: use max value
    exponent = 31;
    mantissa = 7;
  }

  if (exponent < 0) {                           // underflow: use min value
  exponent = 0;
  mantissa = 1;
  }

  return (char)((exponent << 3) | mantissa);    // pack into a byte
}

  /** Computes a score factor based on a term or phrase's frequency in a
   * document.  This value is multiplied by the {@link #idf(Term, Searcher)}
   * factor for each term in the query and these products are then summed to
   * form the initial score for a document.
   *
   * <p>Terms and phrases repeated in a document indicate the topic of the
   * document, so implementations of this method usually return larger values
   * when <code>freq</code> is large, and smaller values when <code>freq</code>
   * is small.
   *
   * <p>The default implementation calls {@link #tf(float)}.
   *
   * @param freq the frequency of a term within a document
   * @return a score factor based on a term's within-document frequency
   */
- (float) tfWithInt: (int) freq
{
  return [self tfWithFloat: (float)freq];
}

  /** Computes the amount of a sloppy phrase match, based on an edit distance.
   * This value is summed for each sloppy phrase match in a document to form
   * the frequency that is passed to {@link #tf(float)}.
   *
   * <p>A phrase match with a small edit distance to a document passage more
   * closely matches the document, so implementations of this method usually
   * return larger values when the edit distance is small and smaller values
   * when it is large.
   *
   * @see PhraseQuery#setSlop(int)
   * @param distance the edit distance of this sloppy phrase match
   * @return the frequency increment for this match
   *                                     */
- (float) sloppyFreq: (int) distance
{
}

  /** Computes a score factor based on a term or phrase's frequency in a
   * document.  This value is multiplied by the {@link #idf(Term, Searcher)}
   * factor for each term in the query and these products are then summed to
   * form the initial score for a document.
   *
   * <p>Terms and phrases repeated in a document indicate the topic of the
   * document, so implementations of this method usually return larger values
   * when <code>freq</code> is large, and smaller values when <code>freq</code>
   * is small.
   *
   * @param freq the frequency of a term within a document
   * @return a score factor based on a term's within-document frequency
   */
- (float) tfWithFloat: (float) freq
{
}

  /** Computes a score factor for a simple term.
   *
   * <p>The default implementation is:<pre>
   *   return idf(searcher.docFreq(term), searcher.maxDoc());
   * </pre>
   *
   * Note that {@link Searcher#maxDoc()} is used instead of
   * {@link IndexReader#numDocs()} because it is proportional to
   * {@link Searcher#docFreq(Term)} , i.e., when one is inaccurate,
   * so is the other, and in the same direction.
   *
   * @param term the term in question
   * @param searcher the document collection being searched
   * @return a score factor for the term
   */
#if 0
- (float) idf: (LCTerm *) term
          searcher: (LCSearcher *) searcher
{
  public float idf(Term term, Searcher searcher) throws IOException {
	      return idf(searcher.docFreq(term), searcher.maxDoc());
  return 0;
}
#endif

  /** Computes a score factor for a phrase.
   *
   * <p>The default implementation sums the {@link #idf(Term,Searcher)} factor
   * for each term in the phrase.
   *
   * @param terms the terms in the phrase
   * @param searcher the document collection being searched
   * @return a score factor for the phrase
   */
#if 0
- (float) idfTerms: (NSArray *) terms
          searcher: (LCSearcher *) searcher
{
  public float idf(Collection terms, Searcher searcher) throws IOException {
	      float idf = 0.0f;
	          Iterator i = terms.iterator();
		      while (i.hasNext()) {
			            idf += idf((Term)i.next(), searcher);
				        }
		          return idf;
  return 0;
}
#endif

  /** Computes a score factor based on a term's document frequency (the number
   * of documents which contain the term).  This value is multiplied by the
   * {@link #tf(int)} factor for each term in the query and these products are
   * then summed to form the initial score for a document.
   *
   * <p>Terms that occur in fewer documents are better indicators of topic, so
   * implementations of this method usually return larger values for rare terms,
   * and smaller values for common terms.
   *
   * @param docFreq the number of documents which contain the term
   * @param numDocs the total number of documents in the collection
   * @return a score factor based on the term's document frequency
   */
- (float) idfDocFreq: (int) docFreq numDocs: (int) numDocs
{
  return 0;
}

  /** Computes a score factor based on the fraction of all query terms that a
   * document contains.  This value is multiplied into scores.
   *
   * <p>The presence of a large portion of the query terms indicates a better
   * match with the query, so implementations of this method usually return
   * larger values when the ratio between these parameters is large and smaller
   * values when the ratio between them is small.
   *
   * @param overlap the number of query terms matched in the document
   * @param maxOverlap the total number of terms in the query
   * @return a score factor based on term overlap with the query
   */
- (float) coord: (int) overlap max: (int) maxOverlap
{
  return 0;
}

@end
