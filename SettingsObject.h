#include "duality/Settings.h"

class SettingsObject : public Settings {
public:
    std::string serverIP() const override;
    void setServerIP(const std::string& ip) override;
    
    std::string serverPort() const override;
    void setServerPort(const std::string& port) override;
    
    bool anatomicalTerms() const override;
    void setAnatomicalTerms(bool enabled) override;
    
    bool cachingEnabled() const override;
    void setCachingEnabled(bool enabled) override;
    
    std::array<float, 3> backgroundColor() const override;
    void setBackgroundColor(const std::array<float, 3>& color) override;
    
    bool useSliceIndices() const override;
    void setUseSliceIndices(bool use) override;
};