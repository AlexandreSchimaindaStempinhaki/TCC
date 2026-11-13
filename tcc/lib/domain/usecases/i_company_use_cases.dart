import '../../../../core/typedefs/types_defs.dart';
import '../../../../core/patterns/i_usecases.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../domain/models/company_entity.dart';

abstract interface class ICreateCompanyUseCase
    implements IUseCase<VoidResult, CreateCompanyParams> {}

abstract interface class IFetchCompaniesByOwnerUseCase
    implements IUseCase<Result<List<CompanyModel>, Failure>, FetchCompaniesByOwnerParams> {}

abstract interface class IFetchCompaniesByMemberUseCase
    implements IUseCase<Result<List<CompanyModel>, Failure>, FetchCompaniesByMemberParams> {}

abstract interface class IUpdateCompanyUseCase
    implements IUseCase<VoidResult, UpdateCompanyParams> {}

abstract interface class IDeleteCompanyUseCase
    implements IUseCase<VoidResult, DeleteCompanyParams> {}