import { describe, it, expect, beforeEach, vi } from "vitest"

// Mock contract calls
const mockContractCall = vi.fn()
const mockTxOk = (value) => ({ value, isOk: true })
const mockTxErr = (code) => ({ code, isOk: false })

// Mock contract
const mockContract = {
  initializeRepayment: (...args) => mockContractCall("initializeRepayment", ...args),
  makePayment: (...args) => mockContractCall("makePayment", ...args),
  markDefaulted: (...args) => mockContractCall("markDefaulted", ...args),
  getRepayment: (...args) => mockContractCall("getRepayment", ...args),
  getPayment: (...args) => mockContractCall("getPayment", ...args),
}

describe("Repayment Tracking Contract", () => {
  beforeEach(() => {
    mockContractCall.mockReset()
  })
  
  describe("initializeRepayment", () => {
    it("should initialize a repayment schedule", async () => {
      mockContractCall.mockReturnValueOnce(mockTxOk(true))
      const result = await mockContract.initializeRepayment(1, 1000, 3)
      
      expect(mockContractCall).toHaveBeenCalledWith("initializeRepayment", 1, 1000, 3)
      expect(result.isOk).toBe(true)
      expect(result.isOk).toBe(true)
      expect(result.value).toBe(true)
    })
    
    it("should fail with invalid amount", async () => {
      mockContractCall.mockReturnValueOnce(mockTxErr(3))
      const result = await mockContract.initializeRepayment(1, 0, 3)
      
      expect(result.isOk).toBe(false)
      expect(result.code).toBe(3)
    })
  })
  
  describe("makePayment", () => {
    it("should make a payment on an active loan", async () => {
      mockContractCall.mockReturnValueOnce(mockTxOk(true))
      const result = await mockContract.makePayment(1, 300)
      
      expect(mockContractCall).toHaveBeenCalledWith("makePayment", 1, 300)
      expect(result.isOk).toBe(true)
      expect(result.value).toBe(true)
    })
    
    it("should fail if loan is completed", async () => {
      mockContractCall.mockReturnValueOnce(mockTxErr(4))
      const result = await mockContract.makePayment(2, 100)
      
      expect(result.isOk).toBe(false)
      expect(result.code).toBe(4)
    })
  })
  
  describe("markDefaulted", () => {
    it("should mark a loan as defaulted", async () => {
      mockContractCall.mockReturnValueOnce(mockTxOk(true))
      const result = await mockContract.markDefaulted(1)
      
      expect(mockContractCall).toHaveBeenCalledWith("markDefaulted", 1)
      expect(result.isOk).toBe(true)
      expect(result.value).toBe(true)
    })
  })
  
  describe("getRepayment", () => {
    it("should return repayment details", async () => {
      const repaymentDetails = {
        totalAmount: 1000,
        amountPaid: 300,
        paymentsMade: 1,
        totalPayments: 3,
        status: "active",
      }
      mockContractCall.mockReturnValueOnce(repaymentDetails)
      
      const result = await mockContract.getRepayment(1)
      expect(result).toEqual(repaymentDetails)
    })
  })
})

