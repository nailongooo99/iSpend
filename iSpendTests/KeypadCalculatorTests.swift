import Testing
@testable import iSpend

struct KeypadCalculatorTests {
    @Test func additionAndMultiplicationPrecedence() { #expect(KeypadCalculator.evaluate("28+32×2") == 92) }
    @Test func divisionByZeroIsRejected() { #expect(KeypadCalculator.evaluate("10÷0") == nil) }
    @Test func zeroAndNegativeTotalsAreRejected() { #expect(KeypadCalculator.evaluate("0") == nil); #expect(KeypadCalculator.evaluate("2−3") == nil) }
}
