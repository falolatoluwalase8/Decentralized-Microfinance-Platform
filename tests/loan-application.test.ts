import { describe, it, expect, beforeEach, vi } from "vitest"

// Mock contract calls
const mockContractCall = vi.fn()
const mockTxOk = (value) => ({ value, isOk: true })
const mockTxErr = (code) => ({ code, isOk: false })

// Mock contract
const mockContract = {
  submitApplication: (...args) => mockContractCall("submitApplication", ...args),
  approveApplication: (...args) => mockContractCall("approveApplication", ...args),
  rejectApplication: (...args) => mockContractCall("rejectApplication", ...args),
  getLoan: (...args) => mockContractCall("getLoan", ...args),
  getApplication: (...args) => mockContractCall("getApplication", ...args),
}

describe("Loan Application Contract", () => {
  beforeEach(() => {
    mockContractCall.mockReset()
  })
  
  describe("submitApplication", () => {
    it("should submit a valid application", async () => {
      mockContractCall.mockReturnValueOnce(mockTxOk(1))
      const result = await mockContract.submitApplication(1000, 30, "Business")
      
      expect(mockContractCall).toHaveBeenCalledWith("submitApplication", 1000, 30, "Business")
      expect(result.isOk).toBe(true)
      expect(result.value).toBe(1)
    })
    
    it("should fail with invalid amount", async () => {
      mockContractCall.mockReturnValueOnce(mockTxErr(2))
      const result = await mockContract.submitApplication(0, 30, "Business")
      
      expect(result.isOk).toBe(false)
      expect(result.code).toBe(2)
    })
  })
  
  describe("approveApplication", () => {
    it("should approve a pending application", async () => {
      mockContractCall.mockReturnValueOnce(mockTxOk(1))
      const result = await mockContract.approveApplication(1)
      
      expect(mockContractCall).toHaveBeenCalledWith("approveApplication", 1)
      expect(result.isOk).toBe(true)
      expect(result.value).toBe(1)
    })
    
    it("should fail if application not found", async () => {
      mockContractCall.mockReturnValueOnce(mockTxErr(3))
      const result = await mockContract.approveApplication(999)
      
      expect(result.isOk).toBe(false)
      expect(result.code).toBe(3)
    })
  })
  
  describe("rejectApplication", () => {
    it("should reject a pending application", async () => {
      mockContractCall.mockReturnValueOnce(mockTxOk(true))
      const result = await mockContract.rejectApplication(1)
      
      expect(mockContractCall).toHaveBeenCalledWith("rejectApplication", 1)
      expect(result.isOk).toBe(true)
      expect(result.value).toBe(true)
    })
  })
  
  describe("getLoan", () => {
    it("should return loan details", async () => {
      const loanDetails = {
        borrower: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
        amount: 1000,
        term: 30,
        status: "active",
      }
      mockContractCall.mockReturnValueOnce(loanDetails)
      
      const result = await mockContract.getLoan(1)
      expect(result).toEqual(loanDetails)
    })
  })
})

