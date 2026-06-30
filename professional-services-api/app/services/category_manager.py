from typing import List
from app.models.category import Category
from app.repositories.category_repository import CategoryRepository
from app.schemas.category import CategoryCreate, CategoryResponse


class CategoryManager:
    def __init__(self, repo: CategoryRepository) -> None:
        self.repo = repo

    async def create(self, data: CategoryCreate) -> CategoryResponse:
        category = Category(
            name=data.name,
            description=data.description
        )
        created = await self.repo.create(category)
        return CategoryResponse.model_validate(created)

    async def get_all(self) -> List[CategoryResponse]:
        categories = await self.repo.get_all()
        return [CategoryResponse.model_validate(c) for c in categories]
