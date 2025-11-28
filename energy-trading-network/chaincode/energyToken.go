package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// Token symbol for the digital coin
const TokenSymbol = "TEC"

// EnergyTokenContract - Smart contract for energy trading between factories
type EnergyTokenContract struct {
	contractapi.Contract
}

// Factory - Represents a factory in the industrial zone
type Factory struct {
	ID               string  `json:"id"`               // Factory identifier (e.g., "Factory01")
	Name             string  `json:"name"`             // Factory name
	EnergyBalance    float64 `json:"energyBalance"`    // Energy tokens balance (in kWh)
	EnergyType       string  `json:"energyType"`       // Type of energy source (solar, wind, footstep)
	CurrencyBalance  float64 `json:"currencyBalance"`  // Balance in TEC (Tunisian Energy Coin)
	DailyConsumption float64 `json:"dailyConsumption"` // Daily energy consumption in kWh
	AvailableEnergy  float64 `json:"availableEnergy"`  // Currently available energy in kWh
}

// EnergyTrade - Represents an energy trade transaction
type EnergyTrade struct {
	TradeID      string  `json:"tradeId"`      // Unique trade identifier
	SellerID     string  `json:"sellerId"`     // Factory selling energy
	BuyerID      string  `json:"buyerId"`      // Factory buying energy
	Amount       float64 `json:"amount"`       // Amount of energy in kWh
	PricePerUnit float64 `json:"pricePerUnit"` // Price per kWh in tokens
	TotalPrice   float64 `json:"totalPrice"`   // Total transaction value
	Timestamp    string  `json:"timestamp"`    // Transaction timestamp
	Status       string  `json:"status"`       // Trade status (pending, completed, cancelled)
}

// InitLedger - Initialize the ledger with sample factories
func (c *EnergyTokenContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	// Create initial factories in the industrial zone
	factories := []Factory{
		{ID: "Factory01", Name: "Solar Manufacturing Plant", EnergyBalance: 1000.0, EnergyType: "solar", CurrencyBalance: 1000.0, DailyConsumption: 800.0, AvailableEnergy: 1200.0},
		{ID: "Factory02", Name: "Wind Power Assembly", EnergyBalance: 800.0, EnergyType: "wind", CurrencyBalance: 800.0, DailyConsumption: 750.0, AvailableEnergy: 850.0},
		{ID: "Factory03", Name: "Tech Production Facility", EnergyBalance: 500.0, EnergyType: "footstep", CurrencyBalance: 500.0, DailyConsumption: 600.0, AvailableEnergy: 450.0},
		{ID: "Factory04", Name: "Heavy Industry Corp", EnergyBalance: 300.0, EnergyType: "solar", CurrencyBalance: 300.0, DailyConsumption: 900.0, AvailableEnergy: 250.0},
		{ID: "Factory05", Name: "Electronics Assembly", EnergyBalance: 600.0, EnergyType: "wind", CurrencyBalance: 600.0, DailyConsumption: 550.0, AvailableEnergy: 700.0},
	}

	// Store each factory in the blockchain ledger
	for _, factory := range factories {
		factoryJSON, err := json.Marshal(factory)
		if err != nil {
			return fmt.Errorf("failed to marshal factory: %v", err)
		}

		// Put factory data on the ledger
		err = ctx.GetStub().PutState(factory.ID, factoryJSON)
		if err != nil {
			return fmt.Errorf("failed to put factory on ledger: %v", err)
		}
	}

	return nil
}

// RegisterFactory - Register a new factory in the industrial zone
func (c *EnergyTokenContract) RegisterFactory(ctx contractapi.TransactionContextInterface,
	factoryID string, name string, initialBalance float64, energyType string, currencyBalance float64,
	dailyConsumption float64, availableEnergy float64) error {

	// Check if factory already exists
	exists, err := c.FactoryExists(ctx, factoryID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("factory %s already exists", factoryID)
	}

	// Create new factory (CurrencyBalance set from parameter)
	factory := Factory{
		ID:               factoryID,
		Name:             name,
		EnergyBalance:    initialBalance,
		EnergyType:       energyType,
		CurrencyBalance:  currencyBalance,
		DailyConsumption: dailyConsumption,
		AvailableEnergy:  availableEnergy,
	}

	// Marshal factory to JSON
	factoryJSON, err := json.Marshal(factory)
	if err != nil {
		return err
	}

	// Save factory to ledger
	return ctx.GetStub().PutState(factoryID, factoryJSON)
}

// MintEnergyTokens - Generate energy tokens when factory produces surplus energy
func (c *EnergyTokenContract) MintEnergyTokens(ctx contractapi.TransactionContextInterface,
	factoryID string, amount float64) error {

	// Validate amount
	if amount <= 0 {
		return fmt.Errorf("amount must be positive")
	}

	// Get factory from ledger
	factory, err := c.GetFactory(ctx, factoryID)
	if err != nil {
		return err
	}

	// Add tokens to factory balance
	factory.EnergyBalance += amount

	// Update factory on ledger
	factoryJSON, err := json.Marshal(factory)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(factoryID, factoryJSON)
}

// TransferEnergy - Transfer energy tokens from one factory to another
func (c *EnergyTokenContract) TransferEnergy(ctx contractapi.TransactionContextInterface,
	fromFactoryID string, toFactoryID string, amount float64) error {

	// Validate amount
	if amount <= 0 {
		return fmt.Errorf("transfer amount must be positive")
	}

	// Get sender factory
	fromFactory, err := c.GetFactory(ctx, fromFactoryID)
	if err != nil {
		return err
	}

	// Check if sender has sufficient balance
	if fromFactory.EnergyBalance < amount {
		return fmt.Errorf("insufficient energy balance: has %.2f, needs %.2f",
			fromFactory.EnergyBalance, amount)
	}

	// Get receiver factory
	toFactory, err := c.GetFactory(ctx, toFactoryID)
	if err != nil {
		return err
	}

	// Transfer tokens
	fromFactory.EnergyBalance -= amount
	toFactory.EnergyBalance += amount

	// Update both factories on ledger
	fromFactoryJSON, err := json.Marshal(fromFactory)
	if err != nil {
		return err
	}

	toFactoryJSON, err := json.Marshal(toFactory)
	if err != nil {
		return err
	}

	err = ctx.GetStub().PutState(fromFactoryID, fromFactoryJSON)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(toFactoryID, toFactoryJSON)
}

// CreateEnergyTrade - Create a new energy trade between factories
func (c *EnergyTokenContract) CreateEnergyTrade(ctx contractapi.TransactionContextInterface,
	tradeID string, sellerID string, buyerID string, amount float64, pricePerUnit float64) error {

	// Check if trade already exists
	tradeJSON, err := ctx.GetStub().GetState(tradeID)
	if err != nil {
		return fmt.Errorf("failed to read trade: %v", err)
	}
	if tradeJSON != nil {
		return fmt.Errorf("trade %s already exists", tradeID)
	}

	// Validate seller has enough energy
	seller, err := c.GetFactory(ctx, sellerID)
	if err != nil {
		return err
	}
	if seller.EnergyBalance < amount {
		return fmt.Errorf("seller has insufficient energy balance")
	}

	// Verify buyer exists
	_, err = c.GetFactory(ctx, buyerID)
	if err != nil {
		return err
	}

	// Calculate total price
	totalPrice := amount * pricePerUnit

	// Get timestamp
	txTimestamp, err := ctx.GetStub().GetTxTimestamp()
	if err != nil {
		return err
	}

	// Create trade record
	trade := EnergyTrade{
		TradeID:      tradeID,
		SellerID:     sellerID,
		BuyerID:      buyerID,
		Amount:       amount,
		PricePerUnit: pricePerUnit,
		TotalPrice:   totalPrice,
		Timestamp:    txTimestamp.String(),
		Status:       "pending",
	}

	// Save trade to ledger
	tradeJSON, err = json.Marshal(trade)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(tradeID, tradeJSON)
}

// ExecuteTrade - Complete an energy trade transaction
func (c *EnergyTokenContract) ExecuteTrade(ctx contractapi.TransactionContextInterface,
	tradeID string) error {

	// Get trade from ledger
	tradeJSON, err := ctx.GetStub().GetState(tradeID)
	if err != nil {
		return fmt.Errorf("failed to read trade: %v", err)
	}
	if tradeJSON == nil {
		return fmt.Errorf("trade %s does not exist", tradeID)
	}

	var trade EnergyTrade
	err = json.Unmarshal(tradeJSON, &trade)
	if err != nil {
		return err
	}

	// Check if trade is already completed
	if trade.Status == "completed" {
		return fmt.Errorf("trade already completed")
	}

	// Verify buyer has enough TEC to pay
	buyer, err := c.GetFactory(ctx, trade.BuyerID)
	if err != nil {
		return err
	}
	if buyer.CurrencyBalance < trade.TotalPrice {
		return fmt.Errorf("buyer has insufficient %s balance: has %.2f, needs %.2f",
			TokenSymbol, buyer.CurrencyBalance, trade.TotalPrice)
	}

	// Transfer energy from seller to buyer (updates energy balances)
	err = c.TransferEnergy(ctx, trade.SellerID, trade.BuyerID, trade.Amount)
	if err != nil {
		return fmt.Errorf("failed to transfer energy: %v", err)
	}

	// After successful energy transfer, move TEC from buyer to seller
	seller, err := c.GetFactory(ctx, trade.SellerID)
	if err != nil {
		return err
	}
	// Reload buyer to ensure latest state
	buyer, err = c.GetFactory(ctx, trade.BuyerID)
	if err != nil {
		return err
	}

	buyer.CurrencyBalance -= trade.TotalPrice
	seller.CurrencyBalance += trade.TotalPrice

	// Persist updated currency balances
	buyerJSON, err := json.Marshal(buyer)
	if err != nil {
		return err
	}
	if err := ctx.GetStub().PutState(buyer.ID, buyerJSON); err != nil {
		return err
	}

	sellerJSON, err := json.Marshal(seller)
	if err != nil {
		return err
	}
	if err := ctx.GetStub().PutState(seller.ID, sellerJSON); err != nil {
		return err
	}

	// Update trade status
	trade.Status = "completed"

	// Save updated trade
	tradeJSON, err = json.Marshal(trade)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(tradeID, tradeJSON)
}

// GetFactory - Retrieve factory information from the ledger
func (c *EnergyTokenContract) GetFactory(ctx contractapi.TransactionContextInterface,
	factoryID string) (*Factory, error) {

	factoryJSON, err := ctx.GetStub().GetState(factoryID)
	if err != nil {
		return nil, fmt.Errorf("failed to read factory: %v", err)
	}
	if factoryJSON == nil {
		return nil, fmt.Errorf("factory %s does not exist", factoryID)
	}

	var factory Factory
	err = json.Unmarshal(factoryJSON, &factory)
	if err != nil {
		return nil, err
	}

	return &factory, nil
}

// GetEnergyBalance - Get the energy token balance of a factory
func (c *EnergyTokenContract) GetEnergyBalance(ctx contractapi.TransactionContextInterface,
	factoryID string) (float64, error) {

	factory, err := c.GetFactory(ctx, factoryID)
	if err != nil {
		return 0, err
	}

	return factory.EnergyBalance, nil
}

// GetCurrencyBalance - Get the TEC balance of a factory
func (c *EnergyTokenContract) GetCurrencyBalance(ctx contractapi.TransactionContextInterface,
	factoryID string) (float64, error) {

	factory, err := c.GetFactory(ctx, factoryID)
	if err != nil {
		return 0, err
	}

	return factory.CurrencyBalance, nil
}

// GetAvailableEnergy - Get the available energy of a factory
func (c *EnergyTokenContract) GetAvailableEnergy(ctx contractapi.TransactionContextInterface,
	factoryID string) (float64, error) {

	factory, err := c.GetFactory(ctx, factoryID)
	if err != nil {
		return 0, err
	}

	return factory.AvailableEnergy, nil
}

// GetEnergyStatus - Get the energy status (surplus/deficit) of a factory
func (c *EnergyTokenContract) GetEnergyStatus(ctx contractapi.TransactionContextInterface,
	factoryID string) (map[string]interface{}, error) {

	factory, err := c.GetFactory(ctx, factoryID)
	if err != nil {
		return nil, err
	}

	// Calculate surplus or deficit
	difference := factory.AvailableEnergy - factory.DailyConsumption
	var status string

	if difference > 0 {
		status = "surplus"
	} else if difference < 0 {
		status = "deficit"
	} else {
		status = "balanced"
	}

	result := map[string]interface{}{
		"factoryId":        factory.ID,
		"factoryName":      factory.Name,
		"availableEnergy":  factory.AvailableEnergy,
		"dailyConsumption": factory.DailyConsumption,
		"difference":       difference,
		"status":           status,
	}

	return result, nil
}

// UpdateAvailableEnergy - Update the available energy of a factory
func (c *EnergyTokenContract) UpdateAvailableEnergy(ctx contractapi.TransactionContextInterface,
	factoryID string, newAvailableEnergy float64) error {

	// Validate amount
	if newAvailableEnergy < 0 {
		return fmt.Errorf("available energy cannot be negative")
	}

	// Get factory from ledger
	factory, err := c.GetFactory(ctx, factoryID)
	if err != nil {
		return err
	}

	// Update available energy
	factory.AvailableEnergy = newAvailableEnergy

	// Update factory on ledger
	factoryJSON, err := json.Marshal(factory)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(factoryID, factoryJSON)
}

// UpdateDailyConsumption - Update the daily consumption of a factory
func (c *EnergyTokenContract) UpdateDailyConsumption(ctx contractapi.TransactionContextInterface,
	factoryID string, newDailyConsumption float64) error {

	// Validate amount
	if newDailyConsumption < 0 {
		return fmt.Errorf("daily consumption cannot be negative")
	}

	// Get factory from ledger
	factory, err := c.GetFactory(ctx, factoryID)
	if err != nil {
		return err
	}

	// Update daily consumption
	factory.DailyConsumption = newDailyConsumption

	// Update factory on ledger
	factoryJSON, err := json.Marshal(factory)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(factoryID, factoryJSON)
}

// GetTrade - Retrieve trade information from the ledger
func (c *EnergyTokenContract) GetTrade(ctx contractapi.TransactionContextInterface,
	tradeID string) (*EnergyTrade, error) {

	tradeJSON, err := ctx.GetStub().GetState(tradeID)
	if err != nil {
		return nil, fmt.Errorf("failed to read trade: %v", err)
	}
	if tradeJSON == nil {
		return nil, fmt.Errorf("trade %s does not exist", tradeID)
	}

	var trade EnergyTrade
	err = json.Unmarshal(tradeJSON, &trade)
	if err != nil {
		return nil, err
	}

	return &trade, nil
}

// GetAllFactories - Query all factories in the industrial zone
func (c *EnergyTokenContract) GetAllFactories(ctx contractapi.TransactionContextInterface) ([]*Factory, error) {
	// Query all factories using range query - use empty strings to get all keys
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var factories []*Factory
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var factory Factory
		err = json.Unmarshal(queryResponse.Value, &factory)
		if err != nil {
			// Skip entries that aren't factories (like trades)
			continue
		}

		// Only include if it has the Factory struct signature (has ID and Name fields)
		if factory.ID != "" && factory.Name != "" {
			factories = append(factories, &factory)
		}
	}

	return factories, nil
}

// FactoryExists - Check if a factory exists in the ledger
func (c *EnergyTokenContract) FactoryExists(ctx contractapi.TransactionContextInterface,
	factoryID string) (bool, error) {

	factoryJSON, err := ctx.GetStub().GetState(factoryID)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return factoryJSON != nil, nil
}

// GetFactoryHistory - Get the transaction history of a factory
func (c *EnergyTokenContract) GetFactoryHistory(ctx contractapi.TransactionContextInterface,
	factoryID string) (string, error) {

	resultsIterator, err := ctx.GetStub().GetHistoryForKey(factoryID)
	if err != nil {
		return "", err
	}
	defer resultsIterator.Close()

	var history []map[string]interface{}
	for resultsIterator.HasNext() {
		response, err := resultsIterator.Next()
		if err != nil {
			return "", err
		}

		var factory Factory
		if len(response.Value) > 0 {
			err = json.Unmarshal(response.Value, &factory)
			if err != nil {
				return "", err
			}
		}

		record := map[string]interface{}{
			"txId":      response.TxId,
			"value":     factory,
			"timestamp": response.Timestamp,
			"isDelete":  response.IsDelete,
		}
		history = append(history, record)
	}

	historyJSON, err := json.Marshal(history)
	if err != nil {
		return "", err
	}

	return string(historyJSON), nil
}

func main() {
	// Create new smart contract
	energyChaincode, err := contractapi.NewChaincode(&EnergyTokenContract{})
	if err != nil {
		fmt.Printf("Error creating energy token chaincode: %v\n", err)
		return
	}

	// Start the chaincode
	if err := energyChaincode.Start(); err != nil {
		fmt.Printf("Error starting energy token chaincode: %v\n", err)
	}
}
