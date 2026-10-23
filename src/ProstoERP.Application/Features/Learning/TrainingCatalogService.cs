namespace ProstoERP.Application.Training
{
    public interface ITrainingCatalogStore
    {
        object GetVideosStatus();
        object GetLevelsStatus();
        object GetLevelTypes();
    }
    public sealed class TrainingCatalogService
    {
        private readonly ITrainingCatalogStore store;
        public TrainingCatalogService(ITrainingCatalogStore store) { this.store = store; }
        public object GetVideosStatus() { return store.GetVideosStatus(); }
        public object GetLevelsStatus() { return store.GetLevelsStatus(); }
        public object GetLevelTypes() { return store.GetLevelTypes(); }
    }
}
