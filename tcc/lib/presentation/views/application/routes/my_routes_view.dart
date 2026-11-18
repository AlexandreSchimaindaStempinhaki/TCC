import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../widgets/animated_three_dots.dart';
import '../../../widgets/my_route_card.dart';
import '../../../widgets/nav_bar.dart';
import '../../mixins/my_routes_logic.dart';

class MyRoutesView extends StatefulWidget {
  const MyRoutesView({super.key});

  @override
  State<MyRoutesView> createState() => _MyRoutesViewState();
}

class _MyRoutesViewState extends State<MyRoutesView> with MyRoutesMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Watch((context) {
      final loading = isLoading.value;
      final routes = filteredJoinedRoutes;
      final query = searchQuery.value;

      return Scaffold(
        extendBody: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Minhas Rotas',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              // BARRA DE PESQUISA IDÊNTICA À DA HOME VIEW
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: theme.dividerColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          theme.brightness == Brightness.dark ? 0.3 : 0.05,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Watch((context) {
                    final hasSearchText = searchQuery.value.trim().isNotEmpty;

                    return TextField(
                      controller: searchController,
                      onChanged: (value) => searchQuery.value = value,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Buscar por destino da rota...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                          child: Icon(
                            Icons.search_rounded,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        suffixIcon: hasSearchText
                            ? IconButton(
                                tooltip: 'Limpar busca',
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  searchQuery.value = '';
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : Container(
                                margin: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.refresh_rounded,
                                    color: colorScheme.onSurface,
                                    size: 16,
                                  ),
                                  tooltip: 'Atualizar rotas',
                                  onPressed: loadMyRoutes,
                                ),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // LISTA REATIVA DE ROTAS
              Expanded(
                child: loading
                    ? Center(
                        child: AnimatedThreeDots(color: colorScheme.primary),
                      )
                    : routes.isEmpty
                        ? RefreshIndicator(
                            color: colorScheme.onSurface,
                            onRefresh: loadMyRoutes,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(32, 80, 32, 100),
                              children: [
                                Icon(
                                  Icons.directions_bus_outlined,
                                  size: 56,
                                  color: colorScheme.secondary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  query.trim().isNotEmpty
                                      ? 'Nenhuma rota encontrada para "${query.trim()}"'
                                      : 'Você ainda não está vinculado a nenhuma rota',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  query.trim().isNotEmpty
                                      ? 'Tente pesquisar por outro nome de destino.'
                                      : 'Suas rotas como passageiro, motorista, gerente ou CEO aparecerão aqui.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: colorScheme.onSurface,
                            onRefresh: loadMyRoutes,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                              itemCount: routes.length,
                              itemBuilder: (context, index) {
                                final item = routes[index];
                                return MyRouteCard(
                                  key: ValueKey('my_route_${item.route.id}'),
                                  route: item.route,
                                  company: item.company,
                                  userRoleBadge: item.roleBadge,
                                  onTap: () => openRouteDetails(context, item),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      );
    });
  }
}