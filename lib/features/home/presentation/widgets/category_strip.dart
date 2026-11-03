import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_routes.dart';
import 'package:tajhizyar/features/products/data/models/category_model.dart';
import 'package:tajhizyar/features/home/presentation/widgets/category_item.dart';

/// نوار افقی اسکرول‌شونده دسته‌بندی‌ها.
///
/// با کلیک روی هر دسته، کاربر به لیست محصولات همان دسته هدایت می‌شود.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({super.key, required this.categories});

  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final CategoryModel category = categories[index];
          return CategoryItem(
            category: category,
            // سوییچ به تب «محصولات» با فیلتر دسته‌بندی (بدون افزودن لایه جدید)
            onTap: () => context.go(
              AppRoutes.productListPath(categoryId: category.id),
            ),
          );
        },
      ),
    );
  }
}
