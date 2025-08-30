import '../services/supabase_service.dart';
import '../models/portfolio_model.dart';
import '../models/holding_model.dart';

class PortfolioService {
  static PortfolioService? _instance;
  static PortfolioService get instance => _instance ??= PortfolioService._();

  PortfolioService._();

  final client = SupabaseService.instance.client;

  // Get user's portfolios
  Future<List<PortfolioModel>> getUserPortfolios(String userId) async {
    try {
      final response = await client
          .from('portfolios')
          .select('*')
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PortfolioModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch portfolios: $error');
    }
  }

  // Get default portfolio for user
  Future<PortfolioModel?> getDefaultPortfolio(String userId) async {
    try {
      final response = await client
          .from('portfolios')
          .select('*')
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      return response != null ? PortfolioModel.fromJson(response) : null;
    } catch (error) {
      throw Exception('Failed to fetch default portfolio: $error');
    }
  }

  // Get portfolio holdings
  Future<List<HoldingModel>> getPortfolioHoldings(String portfolioId) async {
    try {
      final response = await client
          .from('portfolio_holdings')
          .select('''
            *,
            stocks!inner(
              symbol,
              name,
              exchange,
              sector,
              industry,
              stock_prices(
                current_price,
                previous_close
              )
            )
          ''')
          .eq('portfolio_id', portfolioId)
          .order('current_value', ascending: false);

      return (response as List)
          .map((json) => HoldingModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch holdings: $error');
    }
  }

  // Create new portfolio
  Future<PortfolioModel> createPortfolio({
    required String userId,
    required String name,
    String portfolioType = 'individual',
    bool isDefault = false,
  }) async {
    try {
      final response = await client
          .from('portfolios')
          .insert({
            'user_id': userId,
            'name': name,
            'portfolio_type': portfolioType,
            'is_default': isDefault,
          })
          .select()
          .single();

      return PortfolioModel.fromJson(response);
    } catch (error) {
      throw Exception('Failed to create portfolio: $error');
    }
  }

  // Update portfolio
  Future<void> updatePortfolio({
    required String portfolioId,
    String? name,
    double? totalValue,
    double? totalGainLoss,
    double? totalGainLossPercentage,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (totalValue != null) updateData['total_value'] = totalValue;
      if (totalGainLoss != null) updateData['total_gain_loss'] = totalGainLoss;
      if (totalGainLossPercentage != null)
        updateData['total_gain_loss_percentage'] = totalGainLossPercentage;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      await client.from('portfolios').update(updateData).eq('id', portfolioId);
    } catch (error) {
      throw Exception('Failed to update portfolio: $error');
    }
  }

  // Add holding to portfolio
  Future<void> addHolding({
    required String portfolioId,
    required String stockId,
    required double quantity,
    required double averageCost,
  }) async {
    try {
      await client.from('portfolio_holdings').insert({
        'portfolio_id': portfolioId,
        'stock_id': stockId,
        'quantity': quantity,
        'average_cost': averageCost,
        'current_value':
            quantity * averageCost, // Will be updated with real prices
      });
    } catch (error) {
      throw Exception('Failed to add holding: $error');
    }
  }

  // Update holding
  Future<void> updateHolding({
    required String holdingId,
    double? quantity,
    double? averageCost,
    double? currentValue,
    double? totalGainLoss,
    double? gainLossPercentage,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (quantity != null) updateData['quantity'] = quantity;
      if (averageCost != null) updateData['average_cost'] = averageCost;
      if (currentValue != null) updateData['current_value'] = currentValue;
      if (totalGainLoss != null) updateData['total_gain_loss'] = totalGainLoss;
      if (gainLossPercentage != null)
        updateData['gain_loss_percentage'] = gainLossPercentage;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      await client
          .from('portfolio_holdings')
          .update(updateData)
          .eq('id', holdingId);
    } catch (error) {
      throw Exception('Failed to update holding: $error');
    }
  }

  // Remove holding from portfolio
  Future<void> removeHolding(String holdingId) async {
    try {
      await client.from('portfolio_holdings').delete().eq('id', holdingId);
    } catch (error) {
      throw Exception('Failed to remove holding: $error');
    }
  }

  // Calculate and update portfolio totals
  Future<void> recalculatePortfolioTotals(String portfolioId) async {
    try {
      final holdings = await getPortfolioHoldings(portfolioId);

      double totalValue = 0;
      double totalCost = 0;

      for (final holding in holdings) {
        totalValue += holding.currentValue ?? 0;
        totalCost += (holding.quantity * holding.averageCost);
      }

      final totalGainLoss = totalValue - totalCost;
      final totalGainLossPercentage =
          totalCost > 0 ? (totalGainLoss / totalCost) * 100 : 0;

      await updatePortfolio(
        portfolioId: portfolioId,
        totalValue: totalValue,
        totalGainLoss: totalGainLoss,
        totalGainLossPercentage: totalGainLossPercentage,
      );
    } catch (error) {
      throw Exception('Failed to recalculate portfolio: $error');
    }
  }
}
