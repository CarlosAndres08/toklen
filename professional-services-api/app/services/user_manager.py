import uuid
import os
import shutil # Nuevo import
from fastapi import UploadFile

from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserResponse, UserUpdate


class UserNotFoundError(Exception):
    pass

class InvalidImageFormatError(Exception):
    pass


class UserManager:

    def __init__(self, repo: UserRepository) -> None:
        self.repo = repo

    async def get_profile(self, user_id: uuid.UUID) -> UserResponse:
        user = await self.repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError("Usuario no encontrado.")
        return UserResponse.model_validate(user)

    async def update_profile(self, user_id: uuid.UUID, data: UserUpdate) -> UserResponse:
        user = await self.repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError("Usuario no encontrado.")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(user, key, value)

        updated_user = await self.repo.update(user)
        return UserResponse.model_validate(updated_user)

    async def upload_profile_picture(self, user_id: uuid.UUID, file: UploadFile, base_url: str) -> UserResponse:
        user = await self.repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError("Usuario no encontrado.")

        # Validar formato de imagen
        allowed_formats = ["image/jpeg", "image/png", "image/jpg"]
        if file.content_type not in allowed_formats:
            raise InvalidImageFormatError("Formato de imagen no permitido. Solo se aceptan JPG, JPEG, PNG.")

        # Generar nombre de archivo único
        file_extension = file.filename.split(".")[-1]
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        
        # Ruta de guardado
        # Asegurarse de que el directorio de subidas sea el mismo que en main.py
        # La ruta debe ser relativa a la raíz del proyecto para StaticFiles
        upload_dir = os.path.join("static", "uploads", "profiles")
        os.makedirs(upload_dir, exist_ok=True) # Asegurarse de que el directorio exista
        file_path = os.path.join(upload_dir, unique_filename)

        # Guardar archivo físicamente usando shutil para eficiencia
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Generar URL pública
        # La URL debe coincidir con la ruta montada en StaticFiles
        public_url = f"{base_url}/static/uploads/profiles/{unique_filename}"

        # Actualizar URL en la base de datos
        user.profile_picture_url = public_url
        updated_user = await self.repo.update(user)
        
        return UserResponse.model_validate(updated_user)
