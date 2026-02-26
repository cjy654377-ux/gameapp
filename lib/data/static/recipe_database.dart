/// A combination recipe: two specific template IDs → one hidden monster.
class MonsterRecipe {
  final String material1;
  final String material2;
  final String resultTemplateId;

  const MonsterRecipe({
    required this.material1,
    required this.material2,
    required this.resultTemplateId,
  });

  /// Returns true if [a] and [b] template IDs match this recipe (order-agnostic).
  bool matches(String a, String b) =>
      (a == material1 && b == material2) ||
      (a == material2 && b == material1);
}

class RecipeDatabase {
  RecipeDatabase._();

  static const List<MonsterRecipe> all = [
    // 1★ + 2★ → 3★ hidden
    MonsterRecipe(
      material1: 'flame_spirit',
      material2: 'stone_golem',
      resultTemplateId: 'flame_golem',
    ),
    MonsterRecipe(
      material1: 'vine_snake',
      material2: 'wisp',
      resultTemplateId: 'forest_guardian',
    ),
    MonsterRecipe(
      material1: 'thunder_wolf',
      material2: 'mermaid',
      resultTemplateId: 'thunder_mermaid',
    ),
    // 3★ + 4★ → 4★ hidden
    MonsterRecipe(
      material1: 'crystal_turtle',
      material2: 'phoenix',
      resultTemplateId: 'crystal_phoenix',
    ),
    // 4★ + 5★ → 5★ hidden
    MonsterRecipe(
      material1: 'dark_knight',
      material2: 'flame_dragon',
      resultTemplateId: 'shadow_dragon',
    ),
  ];

  /// Find a recipe matching two template IDs. Returns null if no match.
  static MonsterRecipe? findMatch(String templateIdA, String templateIdB) {
    for (final recipe in all) {
      if (recipe.matches(templateIdA, templateIdB)) return recipe;
    }
    return null;
  }
}
