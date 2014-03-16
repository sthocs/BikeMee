#ifndef CACHEMANAGER_H
#define CACHEMANAGER_H

#include <QObject>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>

class CacheManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString cartoJson READ cartoJson NOTIFY cartoChanged)

public:
    CacheManager();
    QString cartoJson() const;

    Q_INVOKABLE void getContracts(bool);
    Q_INVOKABLE void downloadCarto(QString);
    Q_INVOKABLE void getStationDetails(QString);
    Q_INVOKABLE bool removeCacheDir();

signals:
    void contractsUpdated(QString contracts);
    void cartoChanged();
    void gotStationDetails(QString stationDetails);

public slots:
    void getContractsFinished();
    void replyFinished();
    void stationDetailsFinished();

private:
    QNetworkAccessManager* m_manager;
    QString _cartoJson;
    QString _cacheDir;
    QString _currentCity;

};

#endif // CACHEMANAGER_H
